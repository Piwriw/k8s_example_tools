# opentelemetry-collector 一键安装

OpenTelemetry Collector 的 Kubernetes 一键部署说明（基于官方 Helm Chart）。

## 前置条件

- Kubernetes 1.24+
- Helm 4.0+
- 可访问 `ghcr.io` 镜像仓库（如离线环境请提前加载镜像）

## 一键安装

```bash
# 1. 添加 Helm 仓库
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

# 2. 创建命名空间
kubectl create namespace monitoring

# 3. 一键安装（以 deployment 模式为例）
helm upgrade --install otel-collector \
  open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --set mode=deployment \
  --set image.repository="ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-k8s" \
  --set command.name="otelcol-k8s"
```

## 安装模式选择

通过 `mode` 参数切换部署模式（必填）：

| 模式 | 说明 | 适用场景 |
|------|------|----------|
| `deployment` | 默认副本部署 | 中心化聚合（Gateway） |
| `daemonset` | 每节点一个 Pod | 节点级采集（Agent） |
| `statefulset` | 有状态副本 | 需要持久化的场景 |

```bash
# DaemonSet 模式（推荐作为 Agent 采集节点日志/指标）
helm upgrade --install otel-collector \
  open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --set mode=daemonset \
  --set image.repository="ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-k8s" \
  --set command.name="otelcol-k8s"

# StatefulSet 模式
helm upgrade --install otel-collector \
  open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --set mode=statefulset \
  --set image.repository="ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-k8s" \
  --set command.name="otelcol-k8s"
```

## 常用 Presets 一键启用

OpenTelemetry Collector 内置多个 preset，可在使用 `k8sattributes` 等能力时通过参数一键开启：

```bash
# 启用主机日志采集（需 mode=daemonset）
helm upgrade --install otel-collector \
  open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --set mode=daemonset \
  --set image.repository="ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-k8s" \
  --set command.name="otelcol-k8s" \
  --set presets.logsCollection.enabled=true \
  --set presets.hostMetrics.enabled=true \
  --set presets.kubernetesAttributes.enabled=true \
  --set presets.kubeletMetrics.enabled=true \
  --set presets.clusterMetrics.enabled=true
```

## 验证安装

```bash
# 查看 Pod 状态
kubectl get pods -n monitoring -l app.kubernetes.io/name=opentelemetry-collector

# 查看 Service
kubectl get svc -n monitoring

# 查看 Collector 自监控指标（OTLP HTTP）
kubectl port-forward -n monitoring svc/otel-collector-collector 4318:4318 &
curl http://localhost:4318/metrics
```

## 卸载

```bash
helm uninstall otel-collector -n monitoring
kubectl delete namespace monitoring
```

## 升级

```bash
helm repo update
helm upgrade otel-collector \
  open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  --reuse-values
```

## 配置自定义

如需自定义 receivers/exporters/pipelines，将以下内容保存为 `my-values.yaml`，然后执行：

```bash
helm upgrade --install otel-collector \
  open-telemetry/opentelemetry-collector \
  --namespace monitoring \
  -f my-values.yaml
```

`my-values.yaml` 示例：

```yaml
mode: deployment

image:
  repository: ghcr.io/open-telemetry/opentelemetry-collector-releases/opentelemetry-collector-k8s

command:
  name: otelcol-k8s

config:
  exporters:
    otlp:
      endpoint: tempo.monitoring:4317
      tls:
        insecure: true
  service:
    pipelines:
      traces:
        exporters:
          - otlp
```

## 参考

- 官方 Chart：https://github.com/open-telemetry/opentelemetry-helm-charts
- 官方文档：https://opentelemetry.io/docs/kubernetes/getting-started/