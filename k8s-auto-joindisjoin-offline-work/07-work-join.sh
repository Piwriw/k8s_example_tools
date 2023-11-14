#!/bin/bash
set -e

kubeadm reset -f

kubeadm join ${MASTERIP}  --token  ${TOKEN}  --discovery-token-ca-cert-hash ${DISCOVERY_TOKEN_CA_CERT_HASH}