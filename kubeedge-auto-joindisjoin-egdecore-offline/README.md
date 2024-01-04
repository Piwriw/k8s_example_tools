# Introduce
All in one ,Shell  to kubeedge join or disjoin cluster 
## 节点上下线需要环境变量
```bash
export HARBOR_PASSWD=Harbor12345
export HARBOR_USER=admin
export HARBOR_ADDR=http://10.10.101.159:30003
export CLOUD_HOST=10.10.101.159
export TOKEN=e7962a37cf8fe9b92b45fa827ebfec2150394895eb7fec50e777e8af1f60b10d.eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2OTk2Njg0NDF9.gAby8ckyP05zJgTXIgJ8PUMUCDGw2HEonRkV8TV1U7U
export HOSTNAME=edge-01
hostname edge-01
mkdir -p  nodedeploy
tar -zxvf nodedeploy-arm64-1.12.tar.gz -C nodedeploy
./nodedeploy/edgecore-setup.sh join
```