# packages

此目录存放 k9s 二进制文件，用于离线部署安装。

## 获取二进制

运行下载脚本获取 k9s 二进制：

```bash
# 在有网机器上执行
chmod +x k9s-download.sh

# 默认最新版，自动检测架构
./k9s-download.sh

# 指定版本和架构
./k9s-download.sh -v v0.32.5 -a amd64
./k9s-download.sh -v v0.32.5 -a arm64
```

下载完成后当前目录下的 `k9s` 即为目标二进制文件。

注意：此目录下的 k9s 二进制不提交到 git 仓库。
