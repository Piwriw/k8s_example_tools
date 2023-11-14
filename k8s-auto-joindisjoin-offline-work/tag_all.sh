#!/bin/bash
set  -e

 tar -czvf k8s-offline-work.tar.gz 01-setup_work.sh          04-homename_setup.sh      07-work-join.sh              clear-docker.sh           images/work                    tag_all.sh  \
                                   02-docker_install.sh      05-load-image.sh          08-work-disjoin.sh           clear-k8s.sh               package/docker  package/k8s/centeros-amd64.tar.gz   utils \
                                   03-docker_config.sh       06-k8s-setup.sh           Readme.md                 docker-install.sh         repo-setup.sh



