#!/bin/bash
set -e

tar -czvf docker-offline-centeros_x86.tar.gz centos/x86_64 Readme.md clear.sh   setup.sh
#tar -czvf docker-offline-centeros_arm64.tar.gz centos/arm64 Readme.md clear.sh   setup.sh