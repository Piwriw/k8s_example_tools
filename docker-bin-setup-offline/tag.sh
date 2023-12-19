#!/bin/bash
set -e

 tar -czvf docker_amd64.tar.gz  docker_20_amd64.tar.gz setup.sh docker.service
 tar -czvf docker_arm64.tar.gz  docker_20_arm64.tar.gz setup.sh docker.service