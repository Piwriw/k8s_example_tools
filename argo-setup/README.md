# Argo 安装
## 镜像安装包
https://drive.google.com/drive/folders/1StXJe-9jE_ceEXcCc4uFf9WC1LNu8rFc
## heml
```bash
# helm 添加仓库
helm repo add argo https://argoproj.github.io/argo-helm
# helm 拉取文件
helm pull argo/agro --version  0.40.11
# 安装
helm upgrade --install argo argo -n argo --create-namespace 

```