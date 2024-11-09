# rabbitmq-setup
RabbitMQ 是一个开源的消息队列中间件，它实现了高级消息队列协议（AMQP）。作为一个可靠、灵活和可扩展的消息代理，RabbitMQ 提供了在分布式系统中传递和存储消息的功能。
## Info
nodePorts:
amqp: "30071"
amqpTls: "30072"
dist: "30073"
manager: "30074"
epmd: "30075"
metrics: "30076"
username: user
password: admin

## Deploy
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm pull bitnami/rabbitmq 
 helm upgrade --install  rabbitmq rabbitmq -n rabbitmq --create-namespace 

kubectl apply rabbitmq-pvc.yaml  
chmod 777 /pv/rabbitmq-8g
```