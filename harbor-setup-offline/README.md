# Harbor
## 安装
### 修改value
- externalURL: harbor地址
- kubectl label node harbor=work ,Habbor调度节点
```bash
helm upgrade --install harbor harbor -n harbor --create-namespace
```

```bash
kubectl apply -f harbor/harbor.pvc.yaml
如果使用 PV 和 PVC

会出现权限问题
需要 chmod 777 *
```