#!/bin/bash
set -e


# Change owner and group of edgecore
chown root:root /usr/local/bin/edgecore
chmod 0755 /usr/local/bin/edgecore

# Start edgecore service
systemctl enable edgecore
systemctl start edgecore