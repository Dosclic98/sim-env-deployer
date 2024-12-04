#!/bin/bash
ssh -X simulation@localhost -p 2222 "source '/home/simulation/omnetpp/setenv' && omnetpp"
