# Harbor
## 安装
### 修改value
- externalURL: harbor地址
- nodeSelector: 指定节点
```bash
helm upgrade --install harbor helm -n harbor
```

```bash
如果使用 PV 和 PVC

会出现权限问题
需要 chmod 777 *
```