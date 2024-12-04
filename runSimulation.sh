#!/bin/bash
re="^[0-9]+$"
if [[ $1 == "-r" ]] && [[ $2 =~ $re ]]; then
	for i in $(seq 0 $(($2-1))); do ssh -X simulation@localhost -p 2222 "source '/home/simulation/omnetpp/setenv' && cd '/home/simulation/omnetpp-projects/MQTT_MMS_Medium/simulations' && ../src/MQTT_MMS_Medium -r $i -m -u Cmdenv -n '.:../src:../../inet4.5/examples:../../inet4.5/showcases:../../inet4.5/src:../../inet4.5/tests/validation:../../inet4.5/tests/networks:../../inet4.5/tutorials:../../simu5g/emulation:../../simu5g/simulations:../../simu5g/src' -x 'inet.common.selfdoc;inet.linklayer.configurator.gatescheduling.z3;inet.emulation;inet.showcases.visualizer.osg;inet.examples.emulation;inet.showcases.emulation;inet.transportlayer.tcp_lwip;inet.applications.voipstream;inet.visualizer.osg;inet.examples.voipstream;simu5g.simulations.LTE.cars;simu5g.simulations.NR.cars;simu5g.nodes.cars'  --image-path='../../inet4.5/images:../../simu5g/images' omnetpp_new.ini"; done
else
	echo "Requires:"
	prStr="$0 -r <number_of_run>"
	echo $prStr
fi
