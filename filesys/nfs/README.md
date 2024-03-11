# nfs-Deploy
nfs部署文档
## 
修改value.yaml
nfs:
server: 10.10.101.124
path: /**nfs-storage**


```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
kubectl label node <nfsnode> nfs=work

helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=x.x.x.x \
    --set nfs.path=/exported/path

helm upgrade --install nfs-subdir-external-provisioner nfs-subdir-external-provisioner  -n nfs --create-namespace 

```