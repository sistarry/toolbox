# Sub-store脚本管理
---

## 🚀 使用方法

### clash配置

https://raw.githubusercontent.com/sistarry/toolbox/refs/heads/main/Sub-store/clash.yaml

### Mihomo配置

https://raw.githubusercontent.com/sistarry/toolbox/refs/heads/main/Sub-store/convert.js

### 检测落地ip信息

https://raw.githubusercontent.com/sistarry/toolbox/refs/heads/main/Sub-store/ipxx.js

### 重命名脚本

https://raw.githubusercontent.com/sistarry/toolbox/refs/heads/main/Sub-store/rename.js

### 测速脚本

https://raw.githubusercontent.com/xream/scripts/main/surge/modules/sub-store-scripts/check/http_meta_availability.js#concurrency=10&http_meta_host=127.0.0.1&http_meta_port=9876&http_meta_protocol=http&http_meta_proxy_timeout=10000&http_meta_start_delay=3000&keep_incompatible=true&retries=1&retry_delay=1000&show_latency=true&status=204&timeout=1000&url=http%3A%2F%2Fconnectivitycheck.platform.hicloud.com%2Fgenerate_204

### 排序脚本

function operator(proxies) {
  const withLatency = proxies.filter(p => p._latency !== undefined)
  const withoutLatency = proxies.filter(p => p._latency === undefined)


  withLatency.sort((a, b) => Number(a._latency) - Number(b._latency))


  return [...withLatency, ...withoutLatency]
}

### 筛选节点脚本

function operator(proxies) {
  const topn = 10; // 你想筛选前 多少 个节点


  return proxies.slice(0, topn);
}
