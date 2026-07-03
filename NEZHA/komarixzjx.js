// ============================================================
// Komari 探针 · 现代原生卡片 (Scriptable / ListWidget)
// 原生矢量文字渲染，文字清晰、自动适配机型；进度条/波形用小图嵌入
// 每个组件画一个节点；多个同尺寸组件叠成一摞 → 桌面上下滑动切换
//
// 用法：填 baseURL → 桌面加多个同尺寸组件 → 各自参数填 节点名/序号 → 叠放
// ============================================================

// ======================= 配置区 =============================
const CONFIG = {
  baseURL: "https://komari.example.com", // 必填，结尾不带斜杠
  apiKey: "", // 可选
  offlineThreshold: 300,
  pingHours: 1,
  netHours: 1, // 网络折线图时间窗（小时）
};
CONFIG.baseURL = CONFIG.baseURL.replace(/\/+$/, "");
const SELECTOR = (args.widgetParameter || "").trim();
const family = config.widgetFamily || "medium";
// ============================================================

const COL = {
  fg: new Color("#e6edf3"),
  dim: new Color("#8b949e"),
  dim2: new Color("#6e7681"),
  green: new Color("#3fb950"),
  amber: new Color("#d29922"),
  red: new Color("#f85149"),
  blue: new Color("#58a6ff"),
  track: new Color("#ffffff", 0.12),
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
  nodes.sort((a, b) => (a.weight || 0) - (b.weight || 0));
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
// 数据刷新时刻 HH:MM
function hhmm() {
  const t = new Date();
  const p = (n) => (n < 10 ? "0" : "") + n;
  return p(t.getHours()) + ":" + p(t.getMinutes());
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
  g.colors = [new Color("#0d1117"), new Color("#161b22")];
  g.locations = [0, 1];
  w.backgroundGradient = g;
  w.url = URLScheme.forRunningScript();
  w.refreshAfterDate = new Date(Date.now() + 60 * 1000);
  return w;
}

// 一行进度条：固定宽标签 + 进度条（不含百分比/详情）
function barRow(w, label, p, large) {
  const row = w.addStack();
  row.centerAlignContent();
  const lc = row.addStack();
  lc.size = new Size(large ? 46 : 42, large ? 14 : 12);
  const l = lc.addText(label);
  l.font = Font.semiboldSystemFont(large ? 12 : 10);
  l.textColor = COL.dim;
  l.lineLimit = 1;
  const bw = large ? 252 : 236;
  const bh = large ? 9 : 7;
  const img = row.addImage(barImg(p, bw, bh, usageColor(p)));
  img.imageSize = new Size(bw, bh);
}

// 三列并排用：标签在上、进度条在下
function miniCol(parent, label, p, barW, large) {
  const col = parent.addStack();
  col.layoutVertically();
  col.spacing = large ? 5 : 4;
  const l = col.addText(label);
  l.font = Font.semiboldSystemFont(large ? 11 : 9);
  l.textColor = COL.dim;
  const bh = large ? 8 : 7;
  const img = col.addImage(barImg(p, barW, bh, usageColor(p)));
  img.imageSize = new Size(barW, bh);
}

function buildCard(d, fam) {
  const w = baseWidget();
  const large = fam === "large";
  const small = fam === "small";
  w.setPadding(large ? 16 : 13, large ? 17 : 15, large ? 16 : 13, large ? 17 : 15);

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
    // 右上角：uptime + 数据刷新时间
    const rstack = head.addStack();
    rstack.layoutVertically();
    rstack.spacing = 1;
    const up = rstack.addText(d.online ? fu(d.uptime) : "offline");
    up.font = Font.systemFont(11);
    up.textColor = COL.dim;
    up.rightAlignText();
    const rt = rstack.addText("⟳ " + hhmm());
    rt.font = Font.systemFont(9);
    rt.textColor = COL.dim2;
    rt.rightAlignText();
  }

  // 副标题：仅 large 显示系统 + 到期
  if (large) {
    const sub = w.addStack();
    sub.centerAlignContent();
    const s1 = sub.addText(d.sys || "");
    s1.font = Font.systemFont(12);
    s1.textColor = COL.dim2;
    s1.lineLimit = 1;
    if (d.expire != null) {
      sub.addSpacer();
      const s2 = sub.addText("expire " + d.expire + "d");
      s2.font = Font.systemFont(12);
      s2.textColor = COL.dim2;
    }
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

  // ===== 指标进度条（只条）=====
  const ramP = pc(d.ramUsed, d.ramTotal),
    diskP = pc(d.diskUsed, d.diskTotal);
  if (small) {
    barRow(w, "CPU", d.cpu, large);
    w.addSpacer(7);
    barRow(w, "RAM", ramP, large);
    return w;
  }
  // CPU / RAM / DISK 同一行
  const cols = w.addStack();
  cols.layoutHorizontally();
  const colW = large ? 96 : 90;
  miniCol(cols, "CPU", d.cpu, colW, large);
  cols.addSpacer();
  miniCol(cols, "RAM", ramP, colW, large);
  cols.addSpacer();
  miniCol(cols, "DISK", diskP, colW, large);
  // 流量单独一行
  if (d.trafficLimit > 0) {
    w.addSpacer(large ? 12 : 10);
    barRow(w, "TRAF", pc(trafficUsed(d), d.trafficLimit), large);
  }

  w.addSpacer(large ? 14 : 11);

  // ===== 网络折线图（一段时间）=====
  const nr = w.addStack();
  nr.centerAlignContent();
  const nl = nr.addText("NET");
  nl.font = Font.semiboldSystemFont(large ? 12 : 10);
  nl.textColor = COL.dim;
  nr.addSpacer(8);
  const sv = nr.addText(`↓ ${fb(d.netDown)}  ↑ ${fb(d.netUp)}`);
  sv.font = Font.mediumSystemFont(large ? 12 : 10);
  sv.textColor = COL.fg;
  if (d.ping != null || d.loss != null) {
    nr.addSpacer();
    const pl = nr.addText(
      (d.ping != null ? d.ping + "ms" : "--") +
        (d.loss != null ? " · " + d.loss + "%" : "")
    );
    pl.font = Font.systemFont(large ? 11 : 10);
    pl.textColor = COL.dim;
  }

  w.addSpacer(large ? 8 : 6);
  const cw = large ? 320 : 296;
  const ch = large ? 70 : 44;
  const ci = w.addImage(lineChartImg(d.netHist, cw, ch, large));
  ci.imageSize = new Size(cw, ch);

  if (large) {
    w.addSpacer(6);
    const tot = w.addText(`总 ↓ ${fb(d.totalDown)}  ↑ ${fb(d.totalUp)}`);
    tot.font = Font.systemFont(11);
    tot.textColor = COL.dim2;
  }

  return w;
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

// ----------------------- 主流程 ----------------------------
async function main() {
  let widget;
  try {
    if (CONFIG.baseURL.includes("example.com")) {
      widget = errWidget("请先在脚本顶部填写 baseURL");
    } else {
      const nodes = await loadNodes();
      const node = pickNode(nodes, SELECTOR);
      if (!node) {
        widget = errWidget(SELECTOR ? "未找到节点：" + SELECTOR : "无节点数据");
      } else {
        const arr = await loadRecentArr(node.uuid);
        const d = slim(node, arr);
        if (d.online && family !== "small") {
          const [p, hist] = await Promise.all([
            loadPing(node.uuid),
            loadNetHistory(node.uuid),
          ]);
          d.ping = p.ping;
          d.loss = p.loss;
          d.netHist = hist;
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

await main();