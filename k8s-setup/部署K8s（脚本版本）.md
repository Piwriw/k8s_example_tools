# 部署K8s（脚本版本）

## 分发文件（push-file.sh)

```bash
#!/bin/bash
set -e
# 源文件路径
source_file="../k8s-setup"

# 目标主机列表
target_hosts=(
  "root@10.10.103.79:/root"
  "root@10.10.103.80:/root"
  "root@10.10.103.81:/root"
)

# 循环迭代目标主机列表，并使用 scp 命令将文件复制到每个主机
for target_host in "${target_hosts[@]}"; do
  scp -r "$source_file" "$target_host"
done
```

## 部署包括docker（set-up.sh）

### ⚠️注意修改

```bash
# 需要修改
kubeadm join 10.10.101.158:6443 --token m6ygdj.wrlffvuvofffj2c5 --discovery-token-ca-cert-hash 

# 执行bash 传入hostname 参数 会自动设置本机hostname
bash set-up.sh $homename
```

```bash
#!/bin/bash
set -e
# 需要传递harbor  hostname:ip  h
hostname="$1"
initYum(){
  yum install -y wget
  mkdir /etc/yum.repos.d/bak && mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
  wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo
  wget -O /etc/yum.repos.d/epel.repo http://mirrors.cloud.tencent.com/repo/epel-7.repo
  yum clean all && yum makecache
}
setHostname(){
  hostnamectl set-hostname $hostname
  echo "`ip -4 addr show scope global | awk '/inet/ {print $2; exit}' | cut -d '/' -f1` $hostname" >> /etc/hosts
  /etc/init.d/network restart
}
setupdocker(){

  curl -k -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh --version 20.10
  systemctl start docker
  systemctl enable docker
    touch /etc/docker/daemon.json
    echo '{ "exec-opts": ["native.cgroupdriver=systemd"] }' > /etc/docker/daemon.json
      systemctl restart docker
}
setupK8s(){
    bash ./k8s-setup.sh
    # 不使用可能会出现 sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables
    modprobe  br_netfilter
    yum install -y kubeadm-1.20.4 kubelet-1.20.4 kubectl-1.20.4
    systemctl start kubelet
    systemctl enable kubelet
    # 需要修改
    kubeadm join 10.10.101.158:6443 --token m6ygdj.wrlffvuvofffj2c5 --discovery-token-ca-cert-hash sha256:fb74344fe281551bf7c32e1959a1d5a5439a8fa8a5ee209adb4eab0a568b8990
}

if [ -z "$hostname" ]; then
    echo "没有提供参数 需要hostname"
    exit 1  # 退出脚本，并返回非零退出状态
fi

initYum
setHostname
setupdocker
setupK8s
```

### k8s-prepare(k8s-setup.sh)

```bash
#k8s-setup.sh
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
setenforce 0

systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

echo "1" > /proc/sys/net/ipv4/ip_forward
```