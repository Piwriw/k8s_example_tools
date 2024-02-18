# ingrress-setup
## Introduce
nginx ingress的离线安装
版本：
- kubeVersion: '>=1.20.0-0'
- version: 4.8.3
## 修改端口
修改vaule.tcp 的值
## Deploy
````bash
# 选择节点
kubectl label node <node1> ingress=work
# 安装
helm upgrade --install ingress-nginx  ingress-nginx   -n ingress-nginx --create-namespace
````
