#!/bin/bash
set  -e

 tar -czvf K8s-offline-master.tar.gz Readme.md     clear-k8s.sh        docker-install.sh   images/master    \
          k8s-setup.sh        package             repo-setup.sh             \
          clear-docker.sh     docker-conf.sh      homename-setup.sh   k8s-help-install.sh load-image.sh     \
          push-file.sh        set-up-master.sh    tag_all.sh

 tar -czvf K8s-offline-work.tar.gz Readme.md      clear-k8s.sh        docker-install.sh   images/work   \
          k8s-setup.sh        package             repo-setup.sh       set-up-work.sh       \
          clear-docker.sh     docker-conf.sh      homename-setup.sh   k8s-help-install.sh load-image.sh     \
          push-file.sh         tag_all.sh


