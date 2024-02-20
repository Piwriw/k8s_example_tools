# loki-setup
Loki 是一个开源的日志聚合系统的安装
## Deploy
```bash
# 添加Helm repo
helm repo add grafana https://grafana.github.io/helm-charts
# 添加 helm
helm pull grafana/loki-stack
# 部署
helm upgrade --install loki-stack loki-stack     --set fluent-bit.enabled=true,promtail.enabled=false -n monitoring --create-namespace
```