FROM ubuntu:22.04
SHELL ["/bin/bash", "-c"]

# Parameters
ARG VERSION=6.0.3
ARG INET_VERSION=4.5.0
ARG INET_VERSION_SHORT=4.5
ARG SIMU5G_VERSION=1.2.2
ARG INET_PATH=/home/simulation/omnetpp-projects/inet${INET_VERSION_SHORT}
ARG SIMU5G_PATH=/home/simulation/omnetpp-projects/simu5g

# Installing dependencies
RUN apt-get update && apt-get install -f -y openssh-server sudo git build-essential clang lld gdb bison flex perl \
    python3 python3-pip qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
    libqt5opengl5-dev libxml2-dev zlib1g-dev doxygen graphviz \
    libwebkit2gtk-4.0-37 xdg-utils mpi-default-dev\
    && useradd -ms /bin/bash simulation \                      
    && mkdir /var/run/sshd \    
    && ssh-keygen -A \
    && sed -i "s/^.*PasswordAuthentication.*$/PasswordAuthentication no/" /etc/ssh/sshd_config \
    && sed -i "s/^.*X11Forwarding.*$/X11Forwarding yes/" /etc/ssh/sshd_config \
    && grep "^X11UseLocalhost" /etc/ssh/sshd_config || echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
RUN python3 -m pip install --upgrade numpy pandas matplotlib scipy seaborn posix_ipc


USER simulation
WORKDIR /home/simulation

# Download OMNeT++ 6.0.1
RUN wget https://github.com/omnetpp/omnetpp/releases/download/omnetpp-${VERSION}/omnetpp-${VERSION}-linux-x86_64.tgz \
    && tar -xvzf omnetpp-${VERSION}-linux-x86_64.tgz

# Move the specific version in a common folder
RUN mv omnetpp-$VERSION omnetpp

# Changing CWD
WORKDIR /home/simulation/omnetpp
# Setting up OMNeT++ environment
ENV PATH /home/simulation/omnetpp/bin:$PATH
RUN echo "[ -f '$HOME/omnetpp/setenv' ] && source '$HOME/omnetpp/setenv' -f" >> ~/.profile
RUN . ./setenv && \
    ./configure WITH_OSG=no WITH_OSGEARTH=no && make
RUN rm -r doc out test samples misc config.log config.status

# Create omnet projects direcroty
WORKDIR /home/simulation/
RUN mkdir omnetpp-projects
WORKDIR /home/simulation/omnetpp-projects

# Install inet4.5
RUN wget https://github.com/inet-framework/inet/releases/download/v$INET_VERSION/inet-$INET_VERSION-src.tgz -O inet-src.tgz \
    && tar xf inet-src.tgz && rm inet-src.tgz
WORKDIR ${INET_PATH}
RUN source setenv && make makefiles && \
    make -j $(nproc) MODE=release && \
    rm -rf out

# Install simu5g
WORKDIR /home/simulation/omnetpp-projects
RUN wget https://github.com/Unipisa/Simu5G/archive/refs/tags/v${SIMU5G_VERSION}.tar.gz -O simu5g-src.tar.gz \
    && tar xf simu5g-src.tar.gz && rm simu5g-src.tar.gz
RUN mv Simu5G-${SIMU5G_VERSION} simu5g
WORKDIR ${SIMU5G_PATH}
RUN source setenv -f && make makefiles && \
    make -j $(nproc) MODE=release && \
    rm -rf out

# Clone and build my MMS simulation models
WORKDIR /home/simulation/omnetpp-projects
RUN git clone https://github.com/Dosclic98/MQTT_MMS_Medium.git
WORKDIR /home/simulation/omnetpp-projects/MQTT_MMS_Medium
RUN git submodule init
RUN git submodule update
WORKDIR /home/simulation/omnetpp-projects/MQTT_MMS_Medium/src
RUN opp_makemake -f --deep -DINET_IMPORT -I${INET_PATH}/src -I${SIMU5G_PATH}/src -L${INET_PATH}/src -L${SIMU5G_PATH}/src -lINET -lsimu5g -- -lstdc++fs && \
    make MODE=release all && rm MQTT_MMS_Medium && mv ../out/clang-release/src/MQTT_MMS_Medium .

RUN mkdir /home/simulation/.ssh \
    && chmod 700 /home/simulation/.ssh \
    && echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDkL9bQpQESSt44BDSfDTg2AFvlhoudqG4vBUTQAoukfvovveV2lEHLr13LyZ+nVr7hmvw7FengI5iZoR0DnD9ZJ/Oxx6ea7MK8di8XI5nJ7soIzbrbZGataT6ddFdhhk7bHiPQJPPCX4mvf1tMxlRWPBfSVq1/xJ+62w+sQcl5WwfG4fzMxcCWXsG7RABcUFRPzIO3BlKcllK2CiaZZjI/79zgTukrT5YrAsxv/GF+z4fO1ZrHkSIBD+/o5jGBB6BhT1dUFbJO2YMVtzaTdOeGPff9/ZaPP4zSZdjaKom7rMeAbDkN0+1+LrUoGikjVO6cG4M8qbQPp/Fo1zhMpM2mqKsTbt76qRjuAkvL2qVXt9IaHJeo4G94k2pPVNLXDTVZ07n2zI7yYeJionWeXMKWt+z0RgS2t5TQZolDFfqRs1giCzEpr4YN8pSeCfXDB6MfNs6PIU+cmIp3FyCc/kEtr6mpduMPfZoBbBstXA8e/yvTBP5zbn18plI0xnwZRm5avHKsJQTZ4Nn4mBdBBJCL4Zr0cgXqiQAC6vEgtssdTjjxykvzpVVAKz9lKf+F5z+3KwqraAcX3P1mRW+flZcl0Gq+oPUdorOC/xHdcB8bRboNX7CQCObdfUxqMW7idvl6KYz5ol0/eDe2wEJJlQfLZYauipaH4C4KiGFnURa00w== roberta@capamerica" >> /home/simulation/.ssh/authorized_keys
USER root

EXPOSE 22

#CMD ["/usr/sbin/sshd", "-D"]

ENTRYPOINT ["/usr/sbin/sshd", "-D"]
#, "/usr/sbin/sshd && tail -f /dev/null"]
