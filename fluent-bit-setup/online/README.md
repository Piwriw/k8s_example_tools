# fluent-setup
Fluent Bit 是一个轻量级的日志收集器和处理器。它设计用于从各种来源（如应用程序、容器、操作系统等）收集日志数据，并将其发送到不同的目标
## heml
```bash
# helm 添加仓库
# helm 拉取文件
1. helm repo add fluent https://fluent.github.io/helm-charts
2. helm upgrade --install fluent-bit fluent/fluent-bit   
# 安装
helm upgrade --install fluent-bit fluent-bit  -n fluent-bit --create-namespace 

```