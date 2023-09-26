# 批量的一些镜像的处理
## 主要功能
load-image:倒入镜像
push-images:忘harbor等镜像仓库推送镜像
save-images:批量倒出当前docker所有镜像
tah-images:批量tag所有镜像，为了推送镜像准备
## 快速上手
```bash
# 倒入镜像
bash load-image.sh

# 倒出镜像
bash save-images.sh

# tag镜像 传入私有仓库前缀
bash tag.images.sh $harbor:443

# 推送镜像  传入私有仓库前缀 注意修改账户和密码 默认admin Harbor12345
bash push-images.sh  $harbor:443
```