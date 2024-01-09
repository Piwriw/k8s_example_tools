# Minio-setup-offline
安装minio的部署模式
## 配置项目
minio:
账户：admin
密码：admin
手动PV：
需要给挂载路径添加`chmod 777 `，不然会报错
## 部署
```bash
# minio 部署节点添加label
kubectl label node <xx> minio=work
# helm部署
helm upgrade --install minio minio -n minio --create-namespace
# 手动模式PV
kubectl apply -f minio/minio-pv.yaml
chmod 777 /pv/minio-8g
```


