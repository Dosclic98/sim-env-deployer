#!/bin/bash
echo "Saving OMNeT environment image..."
docker save -o omnet_latest.tar.gz omnet:latest
