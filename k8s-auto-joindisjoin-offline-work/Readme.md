# Introduce
All in one,shell work node to join or disjoin cluster

## 版本关系对应

| Docker  | k8s     | calico                                               |
| ------- |---------| ---------------------------------------------------- |
| 20.10.0 | 1.21.14 | v3.10（deprecated in v1.16+, unavailable in v1.22+） |
|         |         |                                                      |
|         |         |                                                      |

## 使用指南
### 需要环境变量
```bash
export HOSTNAME=k8s-work01
export MASTERIP=172.16.8.31:6443
#  kubeadm token create --print-join-command 在master获取
export TOKEN=xxx
export DISCOVERY_TOKEN_CA_CERT_HASH=sha256:xxx
export DOCKER_MODEL=ONLINE | export DOCKER_MODEL=OFFLINE
```
```bash
# 节点上线
bash 01-setup_work.sh join

# 节点下线
bash 02-setup_work.sh disjoin
```