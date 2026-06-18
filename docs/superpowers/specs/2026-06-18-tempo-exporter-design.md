# Tempo Exporter Design

## 概述

为 opentelemetry-collector Helm chart 添加 Grafana Tempo 导出支持，使 traces 数据可以通过 OTLP GRPC 协议发送到 Tempo 后端。

## 动机

当前 chart 默认只配置了 `debug` exporter，所有 traces 数据仅输出到日志。生产环境需要将 traces 发送到实际的存储后端，Grafana Tempo 是常见的开源选择。

## 设计

### 方案选择

采用 **方案 A：仅 GRPC** —— 在 `values.yaml` 中添加 `otlp/grpc` exporter，端点指向 `tempo.tempo:4317`。

选择理由：
- GRPC 性能优于 HTTP，OTel 推荐优先使用 GRPC
- 配置简洁，减少默认配置的复杂度
- 需要时用户可自行添加 HTTP exporter

### 配置变更

#### 1. Exporter 新增

在 `values.yaml` 的 `config.exporters` 中添加：

```yaml
exporters:
  debug: {}
  otlp/grpc:
    endpoint: tempo.tempo:4317
    tls:
      insecure: true
```

- `otlp/grpc`：OTel Collector 标准命名，区分于已有的 `otlp` receiver
- `endpoint: tempo.tempo:4317`：`<service>.<namespace>:<port>` 格式，K8s 集群内部 DNS
- `tls.insecure: true`：集群内通信通常无需 TLS

#### 2. Pipeline 变更

在 traces pipeline 的 exporters 列表中添加 `otlp/grpc`：

```yaml
service:
  pipelines:
    traces:
      exporters:
        - otlp/grpc
        - debug
```

- `otlp/grpc` 放在 `debug` 前面，优先发送到 Tempo
- 保留 `debug` 用于调试

### 不涉及的变更

- 不修改模板文件（无需 K8s 基础设施变更）
- 不添加 preset 开关
- 不修改 ports、service、RBAC 等资源
- 不影响 logs 和 metrics pipeline

### 用户自定义

用户可以通过 values override 修改端点或移除：

```yaml
# 修改端点
config:
  exporters:
    otlp/grpc:
      endpoint: tempo-custom.monitoring:4317
      tls:
        insecure: true

# 移除 Tempo 支持
config:
  exporters:
    otlp/grpc: null
  service:
    pipelines:
      traces:
        exporters:
          - debug
```

## 影响范围

| 文件 | 变更类型 |
|------|----------|
| `chart/opentelemetry-collector/values.yaml` | 修改：添加 exporter 和 pipeline 配置 |

仅修改一个文件，影响最小。
