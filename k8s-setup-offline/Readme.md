# 版本关系对应

| Docker  | k8s     | calico                                               |
| ------- |---------| ---------------------------------------------------- |
| 20.10.0 | 1.21.14 | v3.10（deprecated in v1.16+, unavailable in v1.22+） |
|         |         |                                                      |
|         |         |                                                      |

## 使用指南
需要先手动安装Docker

```bash
# 会输出 需要执行的配置项目 set-up master
bash set-up-master.sh 

# 只做所有worker的准备工作，不包括加入k8s master
bash set-up-worker.sh
```