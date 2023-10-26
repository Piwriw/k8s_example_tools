# prometheus online安装
## heml
```bash
# helm 添加仓库
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
# helm 拉取文件
helm pull prometheus-community/kube-prometheus-stack --version 46.8.0    
# 安装
helm upgrade --install kube-prometheus-stack kube-prometheus-stack  -n monitoring
# 安装pv
kubectl apply -f kube-prometheus-stack/pv.yaml
# 添加权限
chmod 777 /pv/prom-2g
chmod 777 /pv/prom-8g
```