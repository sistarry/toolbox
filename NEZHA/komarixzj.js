// ============================================================
// Komari 探针 · 现代原生卡片 (Scriptable / ListWidget)
// 原生矢量文字渲染，文字清晰、自动适配机型；进度条/波形用小图嵌入
// 每个组件画一个节点；多个同尺寸组件叠成一摞 → 桌面上下滑动切换
//
// 用法：填 baseURL → 桌面加多个同尺寸组件 → 各自参数填 节点名/序号 → 叠放
// 双节点大号卡片：组件选「大号」，参数填「节点A,节点B」（逗号分隔）
// ============================================================

// ======================= 配置区 =============================
const CONFIG = {
  baseURL: "https://komari.665663.xyz", // 必填，结尾不带斜杠
  apiKey: "", // 可选
  offlineThreshold: 120,
  pingHours: 1,
  netHours: 6, // 网络折线图时间窗（小时）
};
CONFIG.baseURL = CONFIG.baseURL.replace(/\/+$/, "");
const SELECTOR = (args.widgetParameter || "").trim();
const family = config.widgetFamily || "medium";
// 双节点：参数里包含逗号，且是大号组件时启用
const DUAL_SELECTORS = SELECTOR.includes(",")
  ? SELECTOR.split(",").map((s) => s.trim()).filter(Boolean)
  : null;
// ============================================================

const COL = {
  fg: new Color("#1c1c1e"),
  dim: new Color("#6e6e73"),
  dim2: new Color("#8e8e93"),
  green: new Color("#34a853"),
  amber: new Color("#c9890a"),
  red: new Color("#d93025"),
  blue: new Color("#1a73e8"),
  track: new Color("#000000", 0.1),
};
function usageColor(p) {
  return p < 50 ? COL.green : p < 80 ? COL.amber : COL.red;
}

// ----------------------- 网络 ------------------------------
async function fetchJSON(path) {
  const req = new Request(CONFIG.baseURL + path);
  req.timeoutInterval = 15;
  if (CONFIG.apiKey) req.headers = { Authorization: "Bearer " + CONFIG.apiKey };
  return await req.loadJSON();
}
async function loadNodes() {
  const res = await fetchJSON("/api/nodes");
  const nodes = (res && res.data) || [];
  nodes.sort((a, b) => (b.weight || 0) - (a.weight || 0));
  return nodes;
}
async function loadRecentArr(uuid) {
  try {
    const r = await fetchJSON("/api/recent/" + uuid);
    return (r && r.data) || [];
  } catch (e) {
    return [];
  }
}
async function loadPing(uuid) {
  try {
    const r = await fetchJSON(`/api/records/ping?uuid=${uuid}&hours=${CONFIG.pingHours}`);
    const d = (r && r.data) || {};
    const t = (d.tasks || [])[0];
    if (t) return { ping: Math.round(t.avg), loss: Math.round(t.loss) };
    const bi = (d.basic_info || [])[0];
    if (bi) return { ping: null, loss: Math.round(bi.loss) };
  } catch (e) {}
  return { ping: null, loss: null };
}
// 一段时间内的网络历史（服务端已降采样），用于折线图
async function loadNetHistory(uuid) {
  try {
    const r = await fetchJSON(
      `/api/records/load?uuid=${uuid}&hours=${CONFIG.netHours}&load_type=network`
    );
    const recs = (r && r.data && r.data.records) || [];
    return recs.map((x) => ({ in: x.net_in || 0, out: x.net_out || 0 }));
  } catch (e) {
    return [];
  }
}
function pickNode(nodes, sel) {
  if (!sel) return nodes[0] || null;
  if (/^\d+$/.test(sel)) return nodes[parseInt(sel, 10) - 1] || null;
  const s = sel.toLowerCase();
  return (
    nodes.find(
      (n) =>
        (n.name || "").toLowerCase().includes(s) ||
        (n.group || "").toLowerCase().includes(s)
    ) || null
  );
}

// ----------------------- 工具 ------------------------------
function isOnline(stat) {
  if (!stat || !stat.updated_at) return false;
  return (Date.now() - new Date(stat.updated_at).getTime()) / 1000 < CONFIG.offlineThreshold;
}
function expireDays(s) {
  if (!s) return null;
  const t = new Date(s).getTime();
  if (isNaN(t) || new Date(s).getFullYear() < 2000) return null;
  return Math.ceil((t - Date.now()) / 86400000);
}
function fb(b) {
  if (b == null) return "-";
  b = Math.abs(b);
  const u = ["B", "K", "M", "G", "T"];
  let i = 0;
  while (b >= 1024 && i < u.length - 1) {
    b /= 1024;
    i++;
  }
  return (b < 10 && i > 0 ? b.toFixed(1) : Math.round(b)) + u[i];
}
function fu(s) {
  if (!s) return "-";
  const d = Math.floor(s / 86400);
  if (d > 0) return d + "d";
  return Math.floor(s / 3600) + "h";
}
function fuZh(s) {
  if (!s) return "-";
  const d = Math.floor(s / 86400);
  if (d > 0) return d + "天";
  const h = Math.floor(s / 3600);
  if (h > 0) return h + "小时";
  return Math.floor(s / 60) + "分钟";
}
function pc(u, t) {
  return t > 0 ? (u / t) * 100 : 0;
}
// 按 traffic_limit_type 计算已用流量
function trafficUsed(d) {
  const up = d.totalUp || 0,
    down = d.totalDown || 0;
  switch (d.trafficType) {
    case "sum":
      return up + down;
    case "min":
      return Math.min(up, down);
    case "up":
      return up;
    case "down":
      return down;
    default:
      return Math.max(up, down); // max
  }
}
function slim(m, arr) {
  const stat = arr.length ? arr[arr.length - 1] : null;
  const online = isOnline(stat);
  const s = stat || {};
  const net = s.network || {},
    ram = s.ram || {},
    disk = s.disk || {},
    load = s.load || {},
    cpu = s.cpu || {};
  return {
    name: m.name || "未命名",
    region: m.region || "",
    sys: m.os || "",
    online,
    uptime: s.uptime || 0,
    expire: expireDays(m.expired_at),
    cpu: online ? cpu.usage || 0 : 0,
    load1: load.load1 || 0,
    load5: load.load5 || 0,
    load15: load.load15 || 0,
    ramUsed: ram.used || 0,
    ramTotal: ram.total || m.mem_total || 0,
    diskUsed: disk.used || 0,
    diskTotal: disk.total || m.disk_total || 0,
    netDown: net.down || 0,
    netUp: net.up || 0,
    totalDown: net.totalDown || 0,
    totalUp: net.totalUp || 0,
    trafficLimit: m.traffic_limit || 0,
    trafficType: m.traffic_limit_type || "max",
    spark: arr.map((p) => (p.network && p.network.down) || 0),
    ping: null,
    loss: null,
  };
}

// ----------------------- 小图：进度条 / 波形 ----------------
function barImg(p, w, h, color) {
  const dc = new DrawContext();
  dc.size = new Size(w, h);
  dc.opaque = false;
  dc.respectScreenScale = true;
  const bg = new Path();
  bg.addRoundedRect(new Rect(0, 0, w, h), h / 2, h / 2);
  dc.addPath(bg);
  dc.setFillColor(COL.track);
  dc.fillPath();
  const fw = Math.max(h, (w * Math.min(Math.max(p, 0), 100)) / 100);
  const fg = new Path();
  fg.addRoundedRect(new Rect(0, 0, fw, h), h / 2, h / 2);
  dc.addPath(fg);
  dc.setFillColor(color);
  dc.fillPath();
  return dc.getImage();
}
// 网络折线面积图：左侧速度纵坐标，下行面积+线，上行细线
function lineChartImg(hist, w, h, large) {
  const dc = new DrawContext();
  dc.size = new Size(w, h);
  dc.opaque = false;
  dc.respectScreenScale = true;
  if (!hist || hist.length < 2) return dc.getImage();
  const ins = hist.map((x) => x.in),
    outs = hist.map((x) => x.out);
  const mx = Math.max.apply(null, ins.concat(outs).concat([1]));
  const n = hist.length;
  const axisW = large ? 42 : 38;
  const px = axisW;
  const pw = w - axisW;
  const xf = (i) => px + (i / (n - 1)) * pw;
  const yf = (v) => h - (v / mx) * (h - 3) - 1.5;

  // 纵坐标：网格线 + 速度刻度（顶=峰值速度，底=0）
  const ticks = [1, 0.5, 0];
  dc.setFont(Font.systemFont(large ? 9 : 8));
  for (const t of ticks) {
    const gy = t === 1 ? 2 : t === 0 ? h - 1 : h / 2;
    dc.setFillColor(new Color("#ffffff", 0.06));
    dc.fillRect(new Rect(px, gy, pw, 0.6));
    dc.setTextColor(COL.dim2);
    dc.setTextAlignedRight();
    const lab = t === 0 ? "0" : fb(mx * t);
    const ly = Math.min(Math.max(gy - 6, 0), h - 11);
    dc.drawTextInRect(lab, new Rect(0, ly, axisW - 5, 11));
  }

  // 下行面积
  const area = new Path();
  area.move(new Point(px, h));
  for (let i = 0; i < n; i++) area.addLine(new Point(xf(i), yf(ins[i])));
  area.addLine(new Point(w, h));
  area.closeSubpath();
  dc.addPath(area);
  dc.setFillColor(new Color("#58a6ff", 0.16));
  dc.fillPath();

  // 下行线
  const ld = new Path();
  ld.move(new Point(px, yf(ins[0])));
  for (let i = 1; i < n; i++) ld.addLine(new Point(xf(i), yf(ins[i])));
  dc.addPath(ld);
  dc.setStrokeColor(new Color("#58a6ff"));
  dc.setLineWidth(1.6);
  dc.strokePath();

  // 上行线
  const lu = new Path();
  lu.move(new Point(px, yf(outs[0])));
  for (let i = 1; i < n; i++) lu.addLine(new Point(xf(i), yf(outs[i])));
  dc.addPath(lu);
  dc.setStrokeColor(new Color("#3fb950"));
  dc.setLineWidth(1);
  dc.strokePath();

  return dc.getImage();
}

// ----------------------- 卡片 ------------------------------
function baseWidget() {
  const w = new ListWidget();
  const g = new LinearGradient();
  g.colors = [new Color("#ffffff", 0.78), new Color("#f2f2f7", 0.7)];
  g.locations = [0, 1];
  w.backgroundGradient = g;
  w.url = URLScheme.forRunningScript();
  w.refreshAfterDate = new Date(Date.now() + 60 * 1000);
  return w;
}

// 在一张图片里绘制完整指标块：标签(左)+百分比(右) 一行，下方细进度条
// 全部用DrawContext精确像素定位，不依赖Stack自动布局，彻底避免对齐误差
function metricImg(label, p, blockW, large) {
  const fs = large ? 13 : 11;
  const barH = large ? 7 : 6;
  const gapY = large ? 6 : 5;
  const totalH = fs + gapY + barH + 2;

  const dc = new DrawContext();
  dc.size = new Size(blockW, totalH);
  dc.opaque = false;
  dc.respectScreenScale = true;

  // 标签：左对齐
  dc.setFont(Font.semiboldSystemFont(fs));
  dc.setTextColor(COL.dim);
  dc.drawText(label, new Point(0, 0));

  // 百分比：右对齐（用 drawTextInRect + setTextAlignedRight，宽度等于blockW，天然贴合右边界）
  dc.setFont(Font.semiboldSystemFont(fs));
  dc.setTextColor(COL.fg);
  dc.setTextAlignedRight();
  dc.drawTextInRect(Math.round(p) + "%", new Rect(0, 0, blockW, fs + 4));

  // 进度条：紧贴标签行下方，宽度=blockW（与标签/百分比共用同一张图、同一坐标系，绝对对齐）
  const barY = fs + gapY;
  const track = new Path();
  track.addRoundedRect(new Rect(0, barY, blockW, barH), barH / 2, barH / 2);
  dc.addPath(track);
  dc.setFillColor(COL.track);
  dc.fillPath();
  const fillW = Math.max(barH, (blockW * Math.min(Math.max(p, 0), 100)) / 100);
  const fill = new Path();
  fill.addRoundedRect(new Rect(0, barY, fillW, barH), barH / 2, barH / 2);
  dc.addPath(fill);
  dc.setFillColor(usageColor(p));
  dc.fillPath();

  return dc.getImage();
}

function metricBlock(parent, label, p, detail, blockW, large) {
  const col = parent.addStack();
  col.layoutVertically();
  col.spacing = 3;

  const fs = large ? 13 : 11;
  const barH = large ? 7 : 6;
  const gapY = large ? 6 : 5;
  const totalH = fs + gapY + barH + 2;
  const img = col.addImage(metricImg(label, p, blockW, large));
  img.imageSize = new Size(blockW, totalH);

  if (detail) {
    const dt = col.addText(detail);
    dt.font = Font.systemFont(large ? 11 : 9.5);
    dt.textColor = COL.dim2;
    dt.lineLimit = 1;
  }
}

function buildCard(d, fam) {
  const w = baseWidget();
  const large = fam === "large";
  const small = fam === "small";
  w.setPadding(large ? 16 : 13, large ? 22 : 20, large ? 16 : 13, large ? 22 : 20);

  // ===== 头部 =====
  const head = w.addStack();
  head.centerAlignContent();
  const dot = head.addText("●");
  dot.font = Font.systemFont(small ? 9 : 10);
  dot.textColor = d.online ? COL.green : COL.dim2;
  head.addSpacer(6);
  const nm = head.addText((d.region ? d.region + " " : "") + d.name);
  nm.font = Font.boldSystemFont(small ? 14 : large ? 18 : 15);
  nm.textColor = COL.fg;
  nm.lineLimit = 1;
  if (!small) {
    head.addSpacer();
    const right = head.addText(d.online ? "在线" + fuZh(d.uptime) : "offline");
    right.font = Font.systemFont(large ? 13 : 11);
    right.textColor = COL.dim2;
  }

  // 副标题：仅 large 显示系统信息
  if (large && d.online) {
    const sub = w.addStack();
    sub.centerAlignContent();
    const s2 = sub.addText(d.sys || "");
    s2.font = Font.systemFont(12);
    s2.textColor = COL.dim2;
    s2.lineLimit = 1;
  }

  if (!d.online) {
    w.addSpacer();
    const off = w.addText("● 节点离线");
    off.font = Font.mediumSystemFont(14);
    off.textColor = COL.dim;
    off.centerAlignText();
    w.addSpacer();
    return w;
  }

  w.addSpacer(large ? 14 : 10);

  // ===== 指标网格（贴近网页：标签+百分比同行，下方细条，再下方用量）=====
  const ramP = pc(d.ramUsed, d.ramTotal),
    diskP = pc(d.diskUsed, d.diskTotal);
  if (small) {
    metricBlock(w, "CPU", d.cpu, null, large ? 280 : 264, large);
    w.addSpacer(8);
    metricBlock(w, "内存", ramP, `${fb(d.ramUsed)} / ${fb(d.ramTotal)}`, large ? 280 : 264, large);
    return w;
  }
  const totalW = large ? 350 : 326;
  const gap = large ? 30 : 26;
  const blockW = (totalW - gap) / 2;

  const row1 = w.addStack();
  row1.layoutHorizontally();
  metricBlock(row1, "CPU", d.cpu, `${d.load1.toFixed(2)} 负载`, blockW, large);
  row1.addSpacer(gap);
  metricBlock(row1, "内存", ramP, `${fb(d.ramUsed)} / ${fb(d.ramTotal)}`, blockW, large);

  w.addSpacer(large ? 12 : 9);

  const row2 = w.addStack();
  row2.layoutHorizontally();
  metricBlock(row2, "硬盘", diskP, `${fb(d.diskUsed)} / ${fb(d.diskTotal)}`, blockW, large);
  row2.addSpacer(gap);
  if (d.trafficLimit > 0) {
    metricBlock(
      row2,
      "流量",
      pc(trafficUsed(d), d.trafficLimit),
      `${fb(trafficUsed(d))} / ${fb(d.trafficLimit)}`,
      blockW,
      large
    );
  } else {
    metricBlock(row2, "流量", 0, `↑ ${fb(d.totalUp)} ↓ ${fb(d.totalDown)}`, blockW, large);
  }

  w.addSpacer(large ? 14 : 11);

  // ===== 流量（累计上传/下载，替代原实时网速行）=====
  const nr = w.addStack();
  nr.centerAlignContent();
  const nl = nr.addText("总流量");
  nl.font = Font.semiboldSystemFont(large ? 13 : 11);
  nl.textColor = COL.dim;
  nr.addSpacer(8);
  const sv = nr.addText(`↓ ${fb(d.totalDown)}  ↑ ${fb(d.totalUp)}`);
  sv.font = Font.mediumSystemFont(large ? 13 : 11);
  sv.textColor = COL.fg;
  if (d.ping != null || d.loss != null) {
    nr.addSpacer();
    const df = new DateFormatter();
    df.dateFormat = "HH:mm";
    df.timeZone = "GMT+8";
    const timeStr = df.string(new Date());
    const pingStr = d.ping != null ? d.ping + "ms" : "--";
    const pl = nr.addText(`${pingStr} · ${timeStr}`);
    pl.font = Font.systemFont(large ? 12 : 11);
    pl.textColor = COL.dim;
  }

  return w;
}

// ===== 双节点精简卡片（仅大号）：克隆中号卡片的经典 2x2 网格排版 =====
function buildOneOfDual(w, d, totalW) {
  // 头部：状态点 + 名称 + 在线时长
  const head = w.addStack();
  head.centerAlignContent();
  const dot = head.addText("●");
  dot.font = Font.systemFont(10);
  dot.textColor = d.online ? COL.green : COL.dim2;
  head.addSpacer(6);
  const nm = head.addText((d.region ? d.region + " " : "") + d.name);
  nm.font = Font.boldSystemFont(15);
  nm.textColor = COL.fg;
  nm.lineLimit = 1;
  head.addSpacer();
  const right = head.addText(d.online ? "在线" + fuZh(d.uptime) : "offline");
  right.font = Font.systemFont(11);
  right.textColor = COL.dim2;

  if (!d.online) {
    w.addSpacer(14); // 调大间隙以自然填充垂直空间
    const off = w.addText("● 节点离线");
    off.font = Font.mediumSystemFont(14);
    off.textColor = COL.dim;
    return;
  }

  w.addSpacer(14); // 调大头部与第一行之间的间隙

  const ramP = pc(d.ramUsed, d.ramTotal),
    diskP = pc(d.diskUsed, d.diskTotal);
  const gap = 26;
  const blockW = (totalW - gap) / 2;

  // 第一行：CPU 与 内存
  const row1 = w.addStack();
  row1.layoutHorizontally();
  metricBlock(row1, "CPU", d.cpu, `${d.load1.toFixed(2)} 负载`, blockW, false);
  row1.addSpacer(gap);
  metricBlock(row1, "内存", ramP, `${fb(d.ramUsed)} / ${fb(d.ramTotal)}`, blockW, false);

  w.addSpacer(12); // 调大第一行与第二行之间的间隙

  // 第二行：硬盘 与 流量
  const row2 = w.addStack();
  row2.layoutHorizontally();
  metricBlock(row2, "硬盘", diskP, `${fb(d.diskUsed)} / ${fb(d.diskTotal)}`, blockW, false);
  row2.addSpacer(gap);
  if (d.trafficLimit > 0) {
    metricBlock(
      row2,
      "流量",
      pc(trafficUsed(d), d.trafficLimit),
      `${fb(trafficUsed(d))} / ${fb(d.trafficLimit)}`,
      blockW,
      false
    );
  } else {
    metricBlock(row2, "流量", 0, `↑ ${fb(d.totalUp)} ↓ ${fb(d.totalDown)}`, blockW, false);
  }

  w.addSpacer(14); // 调大第二行与底栏之间的间隙

  // 底栏：总流量 与 延迟
  const nr = w.addStack();
  nr.centerAlignContent();
  const nl = nr.addText("总流量");
  nl.font = Font.semiboldSystemFont(11);
  nl.textColor = COL.dim;
  nr.addSpacer(8);
  const sv = nr.addText(`↓ ${fb(d.totalDown)}  ↑ ${fb(d.totalUp)}`);
  sv.font = Font.mediumSystemFont(11);
  sv.textColor = COL.fg;
  if (d.ping != null || d.loss != null) {
    nr.addSpacer();
    const df = new DateFormatter();
    df.dateFormat = "HH:mm";
    df.timeZone = "GMT+8"; // 强制锁定北京时间
    const timeStr = df.string(new Date());
    const pingStr = d.ping != null ? d.ping + "ms" : "--";
    const pl = nr.addText(`${pingStr} · ${timeStr}`);
    pl.font = Font.systemFont(11);
    pl.textColor = COL.dim;
  }
}

function buildDualCard(d2, d1) {
  const w = baseWidget();
  // 保持内边距紧凑
  w.setPadding(12, 20, 12, 20);
  const totalW = 326;

  buildOneOfDual(w, d2, totalW);

  w.addSpacer(16); // 增加节点与分割线之间的间距
  const divider = w.addStack();
  divider.size = new Size(totalW, 1);
  divider.backgroundColor = new Color("#000000", 0.08);
  w.addSpacer(16); // 增加分割线与下方节点之间的间距

  buildOneOfDual(w, d1, totalW);

  return w;
}

// ----------------------- 主流程 ----------------------------
async function main() {
  let widget;
  try {
    if (CONFIG.baseURL.includes("example.com")) {
      widget = errWidget("请先在脚本顶部填写 baseURL");
    } else if (DUAL_SELECTORS && family === "large") {
      // ===== 双节点模式：大号组件 + 参数「节点A,节点B」 =====
      const nodes = await loadNodes();
      const n1 = pickNode(nodes, DUAL_SELECTORS[0]);
      const n2 = pickNode(nodes, DUAL_SELECTORS[1]);
      if (!n1 || !n2) {
        widget = errWidget(
          "未找到节点：" + [!n1 ? DUAL_SELECTORS[0] : null, !n2 ? DUAL_SELECTORS[1] : null].filter(Boolean).join(" / ")
        );
      } else {
        const [arr1, arr2] = await Promise.all([
          loadRecentArr(n1.uuid),
          loadRecentArr(n2.uuid),
        ]);
        const d1 = slim(n1, arr1);
        const d2 = slim(n2, arr2);
        const pingPromises = [];
        if (d1.online) pingPromises.push(loadPing(n1.uuid).then((p) => (d1.ping = p.ping, d1.loss = p.loss)));
        if (d2.online) pingPromises.push(loadPing(n2.uuid).then((p) => (d2.ping = p.ping, d2.loss = p.loss)));
        await Promise.all(pingPromises);
        widget = buildDualCard(d1, d2);
      }
    } else {
      const nodes = await loadNodes();
      const node = pickNode(nodes, SELECTOR);
      if (!node) {
        widget = errWidget(SELECTOR ? "未找到节点：" + SELECTOR : "无节点数据");
      } else {
        const arr = await loadRecentArr(node.uuid);
        const d = slim(node, arr);
        if (d.online && family !== "small") {
          const p = await loadPing(node.uuid);
          d.ping = p.ping;
          d.loss = p.loss;
        }
        widget = buildCard(d, family);
      }
    }
  } catch (e) {
    widget = errWidget("请求失败：" + (e.message || e));
  }

  if (config.runsInWidget) Script.setWidget(widget);
  else if (family === "large") widget.presentLarge();
  else if (family === "small") widget.presentSmall();
  else widget.presentMedium();
  Script.complete();
}

function errWidget(msg) {
  const w = baseWidget();
  w.setPadding(14, 16, 14, 16);
  const t = w.addText("⚠️ Komari");
  t.font = Font.boldSystemFont(14);
  t.textColor = COL.red;
  w.addSpacer(6);
  const m = w.addText(msg);
  m.font = Font.systemFont(11);
  m.textColor = COL.fg;
  return w;
}

await main();