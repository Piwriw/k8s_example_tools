## 拓展磁盘（Centos）
pvcreate /dev/sdb     # 创建pv

vgextend centos /dev/sdb    # 扩容vg

lvextend -l +100%FREE /dev/centos/root  # 扩容lv

xfs_growfs /dev/centos/root  # 更新容量