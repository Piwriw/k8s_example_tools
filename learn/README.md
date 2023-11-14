k8s
---

# 1、安装（v.1.17.1,docker-cri）

## 1.1 env.bash

```bash
#!/bin/bash

# 在 master 节点和 worker 节点都要执行

# 卸载旧版本
yum remove docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-engine

# 安装并启动 docker(cri)
yum install -y docker-ce-19.03.5 docker-ce-cli-19.03.5 containerd.io
systemctl enable docker
systemctl start docker

# 关闭 防火墙
systemctl stop firewalld
systemctl disable firewalld

# 关闭 SeLinux
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config

# 关闭 swap
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab

# 修改 /etc/sysctl.conf
# 如果有配置，则修改
sed -i "s#^net.ipv4.ip_forward.*#net.ipv4.ip_forward=1#g"  /etc/sysctl.conf
sed -i "s#^net.bridge.bridge-nf-call-ip6tables.*#net.bridge.bridge-nf-call-ip6tables=1#g"  /etc/sysctl.conf
sed -i "s#^net.bridge.bridge-nf-call-iptables.*#net.bridge.bridge-nf-call-iptables=1#g"  /etc/sysctl.conf
# 可能没有，追加
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
# 执行命令以应用
sysctl -p

docker version				
```

## 1.2 k8ssetup.bash

### 1.2.1 k8ssetup.yaml

```yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v1.17.1
controlPlaneEndpoint: "apiserver.k8s.com:6443"
networking:
  serviceSubnet: "10.96.0.0/16"
  podSubnet: "10.11.10.0/16"
  dnsDomain: "cluster.local
```

### 1.2.2 k8s run setup(single-host Kubernetes cluster)

```bash
# 初始化k8s
kubeadm init --config=k8ssetup.yaml --upload-certs 


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 使用calico网络
kubectl apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml
```

# 2、资源管理

## 2.1Pod

1. 一个pod的所有容器否运行在同一个节点上；一个pod**不能跨越多个节点**
2. pod的隔离：
   1. 同一个pod的容器的部分隔离，容器上彼此完全隔离的，它们构成了容器组，**拥有同一的命名空间**，因此每一个容器都在相同的network和uts命名空间下，它们共享相同的主机名和网络接口，**它们也在相同的IPC命名空间下运行**，能够进行IPC通信
   2. 容器的共享相同的IP和端口空间共享相同的IP地址和端口空间
3. pod的网络上平铺的，所以pod之间的通信不需要经过nat转换技术，就能进行通信

### 2.1.1创建容器

```bash
kubecl create -f pod.yaml
```

### 2.1.2查看容器

```bash
kubectl get po <podname>
kubectl get po <podname> -o yaml
kubectl get po <podname> -o json
```

### 2.1.3查看容器日志

```bash
docker logs <containerid]
#  --previous  可以获得容器崩溃前，上一个容器的日志
kubectl logs <podid> | <podname> -n <pod_namespace> [ --previous]

```

### 2.1.4向pod发送请求

```bash
kubectl port-forward <podname> <localport>:<podport>
```

# 3、标签管理

## 3.1pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-manual-withlabel
  ## 标签管理
  labels:
    env: prod
    app: kubia-manual
spec:
  containers:
    - name: kubia-manual
      image: luksa/kubia
      imagePullPolicy: IfNotPresent
      ports:
        - containerPort: 8080
          protocol: TCP
#  restartPolicy: Always
```



```bash
# 修改pod标签
kubectl label po  kubia-manual-withlabel <env=debug> --overwrite

# 通过标签，过滤pod
kubectl get po -l env
# 不包含标签
kubectl get po -l '!env'
# 有标签，且不为 debug
kubectl get po -l env!=debug

# 使用运算符 in|notin|exists
kubectl get po -l 'env in (prod,debug)'
kubectl get po -l 'env notin (prod,debug)'

```

## 3.2node

```bash
# 筛选node
kubectl get nodes -l gpu=true
```

### 指定调度到特定节点（nodeselector）

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-manual-label-nodeselector
  labels:
    app: kubia-manual
spec:
# 标签匹配
  nodeSelector:
      env: dev
  containers:
    - name: kubia-manual
      image: luksa/kubia
      imagePullPolicy: IfNotPresent
      ports:
        - containerPort: 8080
          protocol: TCP
#  restartPolicy: Always
```



## 3.3命名空间（namespace）

```bash
# 查看所有ns
kubectl get ns -A
# 查看一个命名空间下的pod
kubectl get po -ns default

# 删除ns，会删除旗下所有pod
kubectl delete ns <joohwan-ns>
# 删除ns所有pod，不删除pod
kubectl delete ns <joohwan-ns> --all
# 删除ns几乎所有资源（部分资源比如service，删除之后会被重建）
kubectl delete all -all
```

### 创建ns

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: joohwan-ns
```

# 4、控制器

## 4.1探针

### 4.1.1存活探针

三种探测容器的机制：

1. HTTP Get探针对容器IP地址（自定义制定的端口和路径）执行Http Get请求，探测收到rsp（状态吗2xx｜3xx），容器处于正常，不然**要求重启容器**
2. TCP套接字尝试与端口进行链接，如果连接成功建立，则探测成功，不然就**重启容器**
3. Exce探针在容器内执行任意命令，检查命令的退出状态码，状态码为0，探测成功，不然其他状态码都是failed

#### 基于Http的存活探针

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-liveness
  labels:
    app: kubia-liveness
spec:
  containers:
    - name: kubia-liveness
      image: luksa/kubia-unhealthy
      imagePullPolicy: IfNotPresent
      # 设置存活探针
      livenessProbe:
        httpGet:
          port: 8080
          path: /
        initialDelaySeconds: 15
        timeoutSeconds: 5
        periodSeconds: 10
  restartPolicy: Always
  
```

### 4.1.2就绪探针

就绪探针会定期调用，并确定特定的Pod是否接受客户端请求。

当容易的准备就绪返回时候，标识容器准备好接收请求

一共有三种就绪探针：

1. Exec探针，执行进程的时候吗。容器的状态由进程的退出状态码确定

2. Http Get探针，向容器发送HTTP Get请求，通过响应Http状态码来判断 探针是否准备好
3. TCP Socket探针，它打开一个TCP连接到容器的指定容器。如果连接已建立，则认为容器已准备就绪

就绪探针的工作流程：

就绪探针会在每个一段时间调用，当Pod被报告为尚未就绪，会从服务中删除该Pod直到再次准备就绪。

与存活探针的不同，**存活探针主要是杀死异常的，并重建新的pod**，就绪探针**容器不通过检查，不会被终止或重新启动**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hellok8s-deployment
spec:
  strategy:
     rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  replicas: 3
  selector:
    matchLabels:
      app: hellok8s
  template:
    metadata:
      labels:
        app: hellok8s
    spec:
      containers:
        - image: guangzhengli/hellok8s:bad
          name: hellok8s-container
          #就绪探针
          readinessProbe:
            httpGet:
              path: /healthz
              port: 3000
            initialDelaySeconds: 1
            successThreshold: 5
```



## 4.2 ReplicationController

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: kubia-rc
  labels:
    app: kubia-rc
spec:
# pod数量
  replicas: 3
  #匹配管理pod
  selector:
    app: kubia-rc
   #pod模版文件
  template:
    metadata:
      labels:
        app: kubia-rc
    spec:
      containers:
        - name: kubia-rc
          image: luksa/kubia
          ports:
            - containerPort: 8080
```



### 4.2.1将pod移入或移出ReplicationController的作用域

1. 通过修改pod的label标签来实现，达到与RC能匹配
2. 如果中途pod标签被取消，它将成为一个普通的pod，但是**RC会认为缺少了一个pod，会重建一个新的pod**
3. 如果修改RC的label选择器，那么**原来的pod就脱离了控制**，而RC会**重新新建pod**

### 4.2.2修改pod 模版

1. **修改pod模版，只会影响之后的pod，不影响已经运行的pod**
2. RC的pod的缩容和扩容
   1. `kubectl edit spec.replicas`
   2. `kubectl scale rc kubia --replicas=of 5`

### 4.2.3删除RC

1. 一般的RC删除之后pod也会随之删除，但是RC只是管理，**可以删除RC不删除pod**

```bash
# 使用 --cascade=false 
kubectl delete rc kubia-rc --cascade=false
```

## 4.3 ReplicaSet(RC进化版，更优秀)

1. RS允许匹配缺少某个标签的pod，或者包含某个特定标签的pod

## 4.4 Job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-job
spec:
  template:
    metadata:
      labels:
        app: batch-app
    spec:
      restartPolicy: OnFailure
      containers:
        - name: main
          image: luksa/batch-job
```

运行单个任务的pod，运行完成任务之后不会重启

### 4.4.1顺序运行job pod

一个job运行多次，设置completions

```yaml
...
spec:
# 会一个一个创建pod，一个pod结束再创建下一个
	completions: 5
```

### 4.4.2并行运行job pod

```yaml
...
spec:
	completions: 5
	# 设置最大并行数量
	parllelism: 2
	...
```

### 4.4.3job的缩放

```bash
kubectl scale job multi-completion-batch-job --replacs 3
```

### 4.4.4限制job pod完成任务时间

指定pod中的activeDeadlineSeconds

### job定期运行（Crodjob）

Cronjob创建Job->Job创建pod

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cronjon
spec:
  # 在什么时候运行
  schedule: "0,15,30,45" #	Run every minute
  # pod最迟在预定时间15s开始运行
  startingDeadlineSeconds: 15
  jobTemplate:
    spec:
      template:
        spec:
          containers:
            - name: cronjon
              image: busybox:latest
              imagePullPolicy: IfNotPresent
              command:
                - /bin/sh
                - -c
                - date; echo Hello!
          restartPolicy: OnFailure
```

# 5.Service

为一组相同功能的pod提供单一的不变的接入点

```bash
kubectl expose 创建
```

### 5.1 如何在一个已有的pod，访问service

```bash
# -- 代表kubectl结束，后面是在pod中执行的参数（--不是必须，在不出现歧义的时候，可以不加）
kubectl exec <pod> -- curl -s <http://serviceip>
```

## 5.2配置每次请求来自于同一个pod

```yaml
...
spec:
# 所有 同一个client ip的请求会被转发到同一个pod
	sessionAffinty: ClientIP
```

## 5.3 同一个服务暴露多个端口

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app.kubernetes.io/name: MyApp
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 9376
    - name: https
      protocol: TCP
      port: 443
      targetPort: 9377
```

## 5.4服务发现

1. 服务正常运行还是不能使用ping（使用的虚拟IP，只有结合端口号才有意义）

```bash
kubectl exec <pod> env
```

## 5.5服务对外暴露

### 5.5.1使用NodePort类型的服务

创建NodePort类型资料，让k8s在其所有节点上保留一个端口

### 5.5.2使用负载均衡器

```yaml
apiVersion: v1
kind: Service
metadata:
  name: kubia-lb
  labels:
    app: kubia-lb
spec:
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: kubia
```



# 6.k8s的卷

卷上pod的一个部分，它不能被单独创建或者删除

k8s卷有以下几种：[k8s官网卷](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/#volume-types)

- emptyDir:用于存储临时的简单空目录
- hostPath：用于将目录从工作节点的文件系统挂载到pod中
- nfs：挂载到pod中的nfs共享卷

## 6.1emptyDir卷

空卷，随着pod的生命周期创建和删除

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
    - image: registry.k8s.io/test-webserver
      name: test-container
      volumeMounts:
        # 挂载容器的地址
        - mountPath: /cache
          name: cache-volume
  volumes:
    - name: cache-volume
      emptyDir:
        sizeLimit: 500Mi		
```

## 6.2hostPath卷

**持久卷**，但是pod要和卷在一个主机上

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
    - image: registry.k8s.io/test-webserver
      name: test-container
      volumeMounts:
        - mountPath: /test-pd
          name: test-volume
  volumes:
    - name: test-volume
      hostPath:
        # 宿主上目录位置
        path: /data
        # 此字段为可选
        type: Directory
```

## 6.3持久卷

为了实现nfs，下面引入PersistentVolume（PV，持久卷），以及在这之前需要创建的PersistentVolumeClaim（PVC，持久卷声明）

PVC的三种访问模式（Access Model）状态：

- RWO：ReadWriteOnce,仅仅允许单个节点挂载读写
- ROX：ReadOnlyMany,允许多个节点挂载只读
- RWX：ReadWriteMany,允许多个节点挂载读写这个卷

回收策略：

- Retain -- 手动回收
- Recycle -- 基本擦除 (`rm -rf /thevolume/*`)
- Delete -- 诸如 AWS EBS 或 GCE PD 卷这类关联存储资产也被删除

# 7.ConfigMap和Secret

## 7.1向容器传递命令行参数

### 7.1.1Docker中的命令和参数

#### Dockerfile中的ENTRYOINT和CMD

- ENTRYOINT：定义容器启动的时候被调用的可执行程序
- CMD：指定传递的ENTRYOINT的参数

一些区别：

- 如果只使用`CMD`，则`CMD`提供的命令会作为默认的可执行命令，但是可以在`docker run`命令中覆盖它。
- 如果只使用`ENTRYPOINT`，则`ENTRYPOINT`提供的命令将成为容器的默认可执行命令，不会被`docker run`命令中的参数覆盖。
- 如果同时使用了`ENTRYPOINT`和`CMD`，`CMD`提供的参数会作为`ENTRYPOINT`命令的默认参数。但是可以在`docker run`命令中提供新的参数来覆盖默认参数。

#### shell和exec形式的区别

1. shell形式：node app.js
2. exec形式：["node","app.js"]

从进程来看：

exec：是 node app.js

Shell: 多了一个/bin/sh -c app.js

### 7.1.2k8s中覆盖命令和参数

```yaml
kind: Pod
spec:
	containers:
	- image: some/image
	# command 和args 在成功创建之后无法修改
		command: ["/bin/command"]
		args: ["args1","args2","args3"]
```

## 7.2在容器定义中指定环境变量

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env_base
  labels:
    app: env_vase
spec:
  containers:
    - name: env_base
      image: luksa/fortume:env
      # 设置环境变量，注意 k8s会在每个容器中，自动暴露同namespace下的环境变量
      env:
        - name: INIERVAL
          value: "30"
      imagePullPolicy: IfNotPresent
  restartPolicy: Always
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env_base
  labels:
    app: env_vase
spec:
  containers:
    - name: env_base
      image: luksa/fortume:env
      # 设置环境变量，注意 k8s会在每个容器中，自动暴露同namespace下的环境变量
      env:
        - name: INIERVAL
          value: "30"
        - name: SEC_VAR
          value: "${FIRST_VAR}"
      imagePullPolicy: IfNotPresent
  restartPolicy: Always
  
```

## 7.3ConfigMap

把配置选项配置到单独的configmap，本质就是键值对映射。

**configmap更新会自动推送更新，但是如果是作为环境变量启动的Pod，需要重启Pod才能重新获取**

### 7.3.1创建cm

```bash
# 创建单条记录
kubectl create configmap fortune-config --from-literal=sleep-interval=25

# 创建多条记录
kubectl create configmap myconfigmap --from-literal=bar=bars --from-literal=one=two

# 从文件创建cm，键名 config-fiel.conf
kubectl create configmap my-config --from-file=config-file.conf
# 指定键名
kubectl create configmap my-config --from-file=customkey=config-file.conf
# 从文件夹创建cm
kubectl create configmap my-config --from-file=/path/to/dir
```

### 7.3.2cm设置环境变量

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-demo-pod
spec:
  containers:
    - name: demo
      image: alpine
      command: ["sleep", "3600"]
      env:
        # 定义环境变量
        - name: PLAYER_INITIAL_LIVES # 请注意这里和 ConfigMap 中的键名是不一样的
          valueFrom:
            configMapKeyRef:
              name: game-demo           # 这个值来自 ConfigMap
              key: player_initial_lives # 需要取值的键
        - name: UI_PROPERTIES_FILE_NAME
          valueFrom:
            configMapKeyRef:
              name: game-demo
              key: ui_properties_file_name
      volumeMounts:
      - name: config
        mountPath: "/config"
        readOnly: true
  volumes:
  # 你可以在 Pod 级别设置卷，然后将其挂载到 Pod 内的容器中
  - name: config
    configMap:
      # 提供你想要挂载的 ConfigMap 的名字
      name: game-demo
      # 来自 ConfigMap 的一组键，将被创建为文件
      items:
      - key: "game.properties"
        path: "game.properties"
      - key: "user-interface.properties"
        path: "user-interface.properties"
```

### 7.3.3 cm在pod中作为文件使用

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: mypod
    image: redis
    volumeMounts:
    - name: foo
      mountPath: "/etc/foo"
      readOnly: true
  volumes:
  - name: foo
    configMap:
      name: myconfigmap
```

```yaml
spec:
	containers:
	- image: some/images
	volumeMounts:
	- name: myvolume
	# 挂载某一个file 而不是一个文件夹
		mountPath: /etc/someconfig.conf
		# 挂载其中的某一条数据
		subPath: myconconfig.cong
```

## 7.4Secret

因为cm是不能加密的，sectet提供了更好的安全性

[k8s-seret](https://kubernetes.io/zh-cn/docs/concepts/configuration/secret/#opaque-secret)

### 7.4.1在Docker

当没有Docker配置文件，又想使用secret来访问容器仓库

```shell
kubectl create secret docker-registry secret-tiger-docker \
  --docker-email=tiger@acme.example \
  --docker-username=tiger \
  --docker-password=pass1234 \
  --docker-server=my-registry.example:5000
```

对上面的进行解码：

```bash
kubectl get secret secret-tiger-docker -o jsonpath='{.data.*}' | base64 -d
```

### 7.4.2基本身份认证

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-basic-auth
type: kubernetes.io/basic-auth
stringData:
  username: admin      # kubernetes.io/basic-auth 类型的必需字段
  password: t0p-Secret # kubernetes.io/basic-auth 类型的必需字段
```

# 8.从应用访问Pod元数据以及其他资源

## 8.1Downward API传递元数据

通过Downward API可以在pod中运行的进程暴露pod的云数据。可以给容器传递以下的数据：

- pod的名称
- pod的IP
- pod所在的namespace
- pod运行节点的名称
- pod运行所属的服务账号的名称
- 每个容器请求的CPU和内存的使用量
- 每个容器可以使用的CPU和内存的限制
- pod的标签
- pod的注释

## 8.2K8s 的REST API

```bash
# 获取集群的信息
kubectl cluster-info

# 因为https需要加密 -k 跳过验证
curl https//xxx:8443 -k

# 通过kubectl-proxy 会启动一个代理服务器，之后可以通过8001访问
kubectl proxy
```

# 9.Deployment

一个 Deployment 为 [Pod](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/) 和 [ReplicaSet](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/replicaset/) 提供声明式的更新能力。

- 提供滚动升级的能力
- Deployment由ReplicaSet组成，并且由它接管Pod

## 9.1滚动升级

```bash
# ReplicationController的滚动升级
kubectl roll-update <kubia-v1> <kubia-v2> --image=luksa/kubisa:v2
```

两种升级策略：

1. Rollingupdate，滚动升级，默认策略
2. Recreate：一次性删除所有的旧版本，然后创建新的pod

## 9.2回滚升级

这可以让deployment会滚到以前版本

```bash
# 显示dm的的历史升级记录,kubecyl 创建的时候需要加上 --recored
kubectl rollout history deployment kubia

# 会滚到某一个特定的版本,其中可以通过指定revisionHistoryLimit来限制历史版本数量，默认值是10
kubectl rollout undo deployment kubia --to-reviesion=1
```

## 9.3暂停滚动升级

```bash
# 暂停滚动升级
kubectl rollout pause deployment kubia

# 回复滚动升级
kubectl rollout resume deployment kubia
```

# 10.k8s的架构

主要分为：控制平面、节点

## 10.1控制面的组件

- etcd分布式持久化存储
- API服务器
- 调度器
- 控制器管理器

这些组件用来存储、管理集群状态，不是运行应用的容器

## 10.2工作节点上运行的组件

- Kubectl
- Kubectl服务代理（kube-proxy）
- 容器运行时（Docker、rkt或者其他）

## 10.3附加组件

- Kubernetes DNS服务器
- 仪表器
- Ingress控制器
- Heapster（容器集群监控）
- 容器网络接口插件

# 11.认证方式

目前认证有：

1. 客户端证书
2. 传入http头中的认证token
3. 基于的http认证

## 组

- system：unauthenticated组用于所有认证插件都不会认证客户端身份的请求
- system：authenticated组自动分配一个成功通过认证的用户
- system：service accounts组包含所有在系统中的serviceAccount

### 创建serviceAccount

- 同一个namespcae下，可以共享一个serviceAccount，但是不能夸namespace

```bash
# 创建，会绑定分配一个secret
kubectl create serviceaccount <foo>
```

# 12.污点

- NoSchedule：表示K8S将不会把Pod调度到具有该污点的Node节点上
- PreferNoSchedule：表示K8S将尽量避免把Pod调度到具有该污点的Node节点上
- NoExecute：表示K8S将不会把Pod调度到具有该污点的Node节点上，同时会将Node上已经存在的Pod驱逐出去

```bash
# 添加污点
kubectl taint nodes k8s-node01 check=zhang:NoSchedule
# 删除污点
kubectl taint nodes k8s-node01 check=zhang:NoSchedule-

# pod 污点
tolerations:
- key: "key"
  operator: "Equal"
  value: "value"
  effect: "NoSchedule"
---
tolerations:
- key: "key"
  operator: "Exists"
  effect: "NoSchedule"
```

可以在同一个node节点上设置多个污点（Taints），在同一个pod上设置多个容忍（Tolerations）。Kubernetes处理多个污点和容忍的方式就像一个过滤器：从节点的所有污点开始，然后忽略可以被Pod容忍匹配的污点；保留其余不可忽略的污点，污点的effect对Pod具有显示效果：特别是：

- 如果有至少一个不可忽略污点，effect为NoSchedule，那么Kubernetes将不调度Pod到该节点
- 如果没有effect为NoSchedule的不可忽视污点，但有至少一个不可忽视污点，effect为PreferNoSchedule，那么Kubernetes将尽量不调度Pod到该节点
- 如果有至少一个不可忽视污点，effect为NoExecute，那么Pod将被从该节点驱逐（如果Pod已经在该节点运行），并且不会被调度到该节点（如果Pod还未在该节点运行）

# 13.其他一些资料

- [api list](https://kubernetes.io/docs/reference/kubernetes-api/)
- [kubernetes教程](https://kubernetes.feisky.xyz/concepts/components/apiserver)