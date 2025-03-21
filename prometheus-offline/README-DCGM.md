# dcgm-helm部署
主要功能是监控GPU指标
```bash
# 1.添加helm 仓库
helm repo add gpu-helm-charts \
    https://nvidia.github.io/dcgm-exporter/helm-charts
    
# 2.拉去helm项目到本地
helm pull  gpu-helm-charts/dcgm-
# 注意修改 value.yaml 的nodeSelector 使用 label 不然会给当前所有集群所有节点起一个Pod，造成拉取镜像到浪费
# example: 
#nodeSelector: {
#      gpu=work
#}  

# 3.部署dcgm
helm upgrade --install  dcgm-exporter dcgm-exporter  -nmonitoring

```
## 一些修改
additionalLabels: {
release: kube-prometheus-stack
}
```bash
# Copyright (c) 2020, NVIDIA CORPORATION.  All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

image:
  repository: nvcr.io/nvidia/k8s/dcgm-exporter
  pullPolicy: IfNotPresent
  # Image tag defaults to AppVersion, but you can use the tag key
  # for the image tag, e.g:
  tag: 3.3.0-3.2.0-ubuntu22.04

# Change the following reference to "/etc/dcgm-exporter/default-counters.csv"
# to stop profiling metrics from DCGM
arguments: ["-f", "/etc/dcgm-exporter/dcp-metrics-included.csv"]
# NOTE: in general, add any command line arguments to arguments above
# and they will be passed through.
# Use "-r", "<HOST>:<PORT>" to connect to an already running hostengine
# Example arguments: ["-r", "host123:5555"]
# Use "-n" to remove the hostname tag from the output.
# Example arguments: ["-n"]
# Use "-d" to specify the devices to monitor. -d must be followed by a string
# in the following format: [f] or [g[:numeric_range][+]][i[:numeric_range]]
# Where a numeric range is something like 0-4 or 0,2,4, etc.
# Example arguments: ["-d", "g+i"] to monitor all GPUs and GPU instances or
# ["-d", "g:0-3"] to monitor GPUs 0-3.
# Use "-m" to specify the namespace and name of a configmap containing
# the watched exporter fields.
# Example arguments: ["-m", "default:exporter-metrics-config-map"]

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""
namespaceOverride: ""

runtimeClassName: ""

serviceAccount:
  # Specifies whether a service account should be created
  create: true
  # Annotations to add to the service account
  annotations: {}
  # The name of the service account to use.
  # If not set and create is true, a name is generated using the fullname template
  name:

rollingUpdate:
  # Specifies maximum number of DaemonSet pods that can be unavailable during the update
  maxUnavailable: 1
  # Specifies maximum number of nodes with an existing available DaemonSet pod that can have an updated DaemonSet pod during during an update
  maxSurge: 0

podLabels: {}

podAnnotations: {
   prometheus.io/scrape: "true",
   prometheus.io/port: "9400"
}
# Using this annotation which is required for prometheus scraping


podSecurityContext: {}
  # fsGroup: 2000

securityContext:
  runAsNonRoot: false
  runAsUser: 0
  capabilities:
     add: ["SYS_ADMIN"]
  # readOnlyRootFilesystem: true

service:
  enable: true
  type: ClusterIP
  port: 9400
  address: ":9400"
  # Annotations to add to the service
  annotations: {}

resources: {}
  # limits:
  #   cpu: 100m
  #   memory: 128Mi
  # requests:
  #   cpu: 100m
  #   memory: 128Mi
serviceMonitor:
  enabled: true
  interval: 15s
  honorLabels: false
  additionalLabels: {
    release: kube-prometheus-stack
  }
    #monitoring: prometheus
  relabelings:
     - sourceLabels: [__meta_kubernetes_pod_node_name]
       separator: ;
       regex: ^(.*)$
       targetLabel: nodename
       replacement: $1
       action: replace

nodeSelector: {
     gpu: work
}
  #node: gpu

tolerations: []
#- operator: Exists

affinity: {}
  #nodeAffinity:
  #  requiredDuringSchedulingIgnoredDuringExecution:
  #    nodeSelectorTerms:
  #    - matchExpressions:
  #      - key: nvidia-gpu
  #        operator: Exists

extraHostVolumes: []
#- name: host-binaries
#  hostPath: /opt/bin

extraConfigMapVolumes: []
#- name: exporter-metrics-volume
#  configMap:
#    name: exporter-metrics-config-map

extraVolumeMounts: []
#- name: host-binaries
#  mountPath: /opt/bin
#  readOnly: true

extraEnv: []
#- name: EXTRA_VAR
#  value: "TheStringValue"

kubeletPath: "/var/lib/kubelet/pod-resources"
```
## 参考网站
https://nvidia.github.io/dcgm-exporter/

https://docs.nvidia.com/datacenter/cloud-native/gpu-telemetry/latest/dcgm-exporter.html