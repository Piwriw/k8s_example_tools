# Docker-Shell
## Introduce
一些组建的docker安装
## mysql
mysql
版本：8.0.26
密码：root
```bash
docker run -d --name mysql_container -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -v /data/mysql:/var/lib/mysql mysql:8.0.26
```
## redis
```bash
docker run -d --name mysql_container -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -v /data/mysql:/var/lib/mysql mysql:8.0.26
```
## minio
版本：2021-02-14T04-01-33Z
账户名称：admin
密码：admin123

```bash
docker run -p 9000:9000 -p 9090:9090 \
--name minio_container \
-d  \
-e "MINIO_ACCESS_KEY=admin" \
-e "MINIO_SECRET_KEY=admin123" \
-v /data/minio/data:/data \
-v /data/minio/config:/root/.minio \
minio/minio:RELEASE.2021-02-14T04-01-33Z  server /data 
```