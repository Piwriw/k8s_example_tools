#!/bin/bash
set -e
# arm64 kubeedge-1.12 部署包
cp ./dependence/docker_arm64.tar.gz ./dependence/docker.tar.gz
cp ./dependence/edgecore_arm64_1-12-x.tar.gz ./dependence/edgecore.tar.gz
cp ./arm64-version.txt ./dependence/arch.txt
cp ../../build/docker_daemon_utils.arm64 ./dependence/docker_daemon_utils
tar -czvf nodedeploy-arm64-1.12.tar.gz \
         edgecore-setup.sh \
          01-docker_install.sh  \
          02-docker_config.sh   \
          03-edgecore_install.sh  \
          04-edgecore_config.sh   \
          05-stopwalld.sh \
          06-edgecore_join.sh    \
          07-edgecore_disjoin.sh \
         ./dependence/docker.tar.gz \
         ./dependence/edgecore.tar.gz \
         ./dependence/arch.txt \
         ./dependence/docker_daemon_utils

rm -rf ./dependence/docker.tar.gz
rm -rf ./dependence/edgecore.tar.gz
rm -rf ./dependence/arch.txt
rm -rf ./dependence/docker_daemon_utils

# x86 kubeedge-1.12 部署包
cp ./dependence/docker_amd64.tar.gz ./dependence/docker.tar.gz
cp ./dependence/edgecore_x86_1-12-x.tar.gz ./dependence/edgecore.tar.gz
cp ./x86-version.txt ./dependence/arch.txt
cp ../../build/docker_daemon_utils.amd64 ./dependence/docker_daemon_utils
tar -czvf nodedeploy-amd64-1.12.tar.gz \
         edgecore-setup.sh \
          01-docker_install.sh  \
          02-docker_config.sh   \
          03-edgecore_install.sh  \
          04-edgecore_config.sh   \
          05-stopwalld.sh \
          06-edgecore_join.sh    \
          07-edgecore_disjoin.sh \
         ./dependence/docker.tar.gz \
         ./dependence/edgecore.tar.gz \
         ./dependence/arch.txt  \
         ./dependence/docker_daemon_utils

rm -rf ./dependence/docker.tar.gz
rm -rf ./dependence/edgecore.tar.gz
rm -rf ./dependence/arch.txt
rm -rf   ./dependence/docker_daemon_utils

# arm64 kubeedge-1.7 部署包
cp ./dependence/docker_arm64.tar.gz ./dependence/docker.tar.gz
cp ./dependence/edgecore_arm64_1-7-x.tar.gz ./dependence/edgecore.tar.gz
cp ./arm64-version.txt ./dependence/arch.txt
cp ../../build/docker_daemon_utils.arm64 ./dependence/docker_daemon_utils
tar -czvf nodedeploy-arm64-1.7.tar.gz \
         edgecore-setup.sh \
          01-docker_install.sh  \
          02-docker_config.sh   \
          03-edgecore_install.sh  \
          04-edgecore_config.sh   \
          05-stopwalld.sh \
          06-edgecore_join.sh    \
          07-edgecore_disjoin.sh \
         ./dependence/docker.tar.gz \
         ./dependence/edgecore.tar.gz \
          ./dependence/arch.txt  \
         ./dependence/docker_daemon_utils

rm -rf ./dependence/docker.tar.gz
rm -rf ./dependence/edgecore.tar.gz
rm -rf ./dependence/arch.txt
rm -rf  ./dependence/docker_daemon_utils

# x86 kubeedge-1.7 部署包
cp ./dependence/docker_amd64.tar.gz ./dependence/docker.tar.gz
cp ./dependence/edgecore_x86_1-7-x.tar.gz ./dependence/edgecore.tar.gz
cp ./x86-version.txt ./dependence/arch.txt
cp ../../build/docker_daemon_utils.amd64 ./dependence/docker_daemon_utils
tar -czvf nodedeploy-amd64-1.7.tar.gz \
         edgecore-setup.sh \
          01-docker_install.sh  \
          02-docker_config.sh   \
          03-edgecore_install.sh  \
          04-edgecore_config.sh   \
          05-stopwalld.sh \
          06-edgecore_join.sh    \
          07-edgecore_disjoin.sh \
         ./dependence/docker.tar.gz \
         ./dependence/edgecore.tar.gz \
            ./dependence/arch.txt  \
          ./dependence/docker_daemon_utils


rm -rf ./dependence/docker.tar.gz
rm -rf ./dependence/edgecore.tar.gz
rm -rf    ./dependence/arch.txt
rm -rf   ./dependence/docker_daemon_utils