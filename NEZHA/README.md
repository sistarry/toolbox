# 哪吒监控 美化代码
---

## 🚀 使用方法

### 哪吒详情页直接展示网络波动卡片 (网络卡片在上)(源自https://www.nodeseek.com/post-607309-1)
```bash
<script src="https://cdn.jsdelivr.net/gh/duya07/nezha-ui@main/netstatus-autoshow-2.js"></script>
```

### 隐藏概览条(源自https://www.nodeseek.com/post-607309-1)
```bash
/* 隐藏迷你概览条 */
<script>
  window.MiniStatsConfig = {
    hideMiniStats: true,       // true: 开启隐藏迷你概览条
    hideParentSection: true    // true: 连同外框一起隐藏 (防止留下一条空白间距)
  };
</script>
<script src="https://cdn.jsdelivr.net/gh/duya07/nezha-ui@main/nezha-mini-stats-hide.js"></script>
```

### 概览条增加半透明背景(源自https://www.nodeseek.com/post-607309-1)
```bash
/* 迷你概览条半透明背景 */
<script src="https://cdn.jsdelivr.net/gh/duya07/nezha-ui@main/nezha-mini-stats-style.js"></script>
```

### 周期性流量进度条(源自https://www.nodeseek.com/post-357843-1)
```bash
/* 周期性流量进度条 */
<script>
  window.TrafficScriptConfig = {
    showTrafficStats: true,    // 显示流量统计
    insertAfter: true,         // 如果开启总流量卡片, 放置在总流量卡片后面
    interval: 60000,           // 60秒刷新缓存, 单位毫秒
    toggleInterval: 4000,      // 4秒切换流量进度条右上角内容, 0秒不切换, 单位毫秒
    duration: 500,             // 缓进缓出切换时间, 单位毫秒
    enableLog: false           // 开启日志
  };
</script>
<script src="https://cdn.jsdelivr.net/gh/ziwiwiz/nezha-ui@main/traffic-progress.js"></script>
```

### 看板娘
```bash
<script src="https://cdn.jsdelivr.net/gh/sistarry/toolbox/NEZHA/kbn.js"></script>
```

### ip胶囊
```bash
<script src="https://cdn.jsdelivr.net/gh/sistarry/toolbox/NEZHA/ip.js"></script>
```

### 自定义代码
```bash
<script>
    window.CustomBackgroundImage = 'https://'; #桌面壁纸
    window.CustomMobileBackgroundImage = 'https://'; #移动壁纸
    window.CustomLogo = 'https://'; #logo
    window.ShowNetTransfer = false;
    window.ForceTheme = "dark";  #暗色
    window.DisableAnimatedMan = true;
    window.ForceUseSvgFlag = false;
    window.CustomLinks = '[{\"link\":\"https://链接/\",\"name\":\"名称\"}]';
</script>
```

### 美化字体(源自https://www.nodeseek.com/post-328904-1)
```bash
<!-- 引入Mi Sans字体 -->
<style>
    /* 引入小米字体 */
    @import url('https://cdn-font.hyperos.mi.com/font/css?family=MiSans:400,500,600,700:Chinese_Simplify,Latin&display=swap');
    
    /* 设置页面字体 */
    * {
        font-family: 'MiSans', sans-serif !important; /* 设置所有元素使用小米字体 */
    }
    h1, h2, h3, h4, h5 {
        font-family: 'MiSans', sans-serif !important; /* 设置标题使用小米字体 */
        font-weight: 600; /* 标题使用粗体 */
    }
</style>

```


### 仪表盘给哪吒后台服务器ip添加itdog ping跳转(源自https://www.nodeseek.com/post-450069-1)
```bash
<script src="https://cdn.jsdelivr.net/gh/leuxinovo/nezha-ui@main/nezha-pingx.js"></script>
```

### 全国各省份三网 TCP-Ping IPv4 地址

https://www.nodeseek.com/post-68572-1

### 全国各省份三网 TCP-Ping IPv6 地址

https://www.nodeseek.com/post-129987-1

