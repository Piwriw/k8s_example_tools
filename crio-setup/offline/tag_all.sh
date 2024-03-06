#!/bin/bash
set  -e

 tar -czvf crio-work.tar.gz dependence/crio dependence/podman image/work \
node/00-set-up-work.sh        node/01-close-firewalld.sh 02-homename-setup.sh  node/03-load-image.sh      node/04-install-crio.sh





