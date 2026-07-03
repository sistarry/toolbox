<script>
(function(){
  var ICONS = {
    'CPU': {
      color: '#4263eb',
      svg: '<rect x="7" y="7" width="10" height="10" rx="1" stroke-width="1.5"/>' +
           '<rect x="10" y="10" width="4" height="4" fill="#4263eb" stroke="none"/>' +
           '<path stroke-width="1.5" d="M9 2v3M12 2v3M15 2v3M9 19v3M12 19v3M15 19v3M2 9h3M2 12h3M2 15h3M19 9h3M19 12h3M19 15h3"/>'
    },
    '内存': {
      color: '#2f9e44',
      svg: '<rect x="2" y="8" width="20" height="9" rx="1.5" stroke-width="1.5"/>' +
           '<path stroke-width="1.5" d="M6 8v9M9.5 8v9M13 8v9M16.5 8v9M20 8v9"/>' +
           '<path stroke-width="1.5" d="M5 8V5M9 8V5M13 8V5M17 8V5"/>'
    },
    '硬盘': {
      color: '#e8590c',
      svg: '<rect x="2" y="4" width="20" height="5" rx="1.5" stroke-width="1.5"/>' +
           '<rect x="2" y="10" width="20" height="5" rx="1.5" stroke-width="1.5"/>' +
           '<rect x="2" y="16" width="20" height="5" rx="1.5" stroke-width="1.5"/>' +
           '<circle cx="6" cy="6.5" r="0.9" fill="#e8590c" stroke="none"/>' +
           '<circle cx="6" cy="12.5" r="0.9" fill="#e8590c" stroke="none"/>' +
           '<circle cx="6" cy="18.5" r="0.9" fill="#e8590c" stroke="none"/>'
    },
    '流量': {
      color: '#7048e8',
      svg: '<path stroke-width="1.6" d="M7.5 19L7.5 5M7.5 5L4.5 8.5M7.5 5L10.5 8.5"/>' +
           '<path stroke-width="1.6" d="M16.5 5L16.5 19M16.5 19L13.5 15.5M16.5 19L19.5 15.5"/>'
    }
  };
  var FREE_PLAN_RE = /^免费\s*\/\s*.+$/;
  var ZERO_PRICE_RE = /^\$0(\.0+)?$/;

  function makeIconHTML(cfg){
    return '<svg class="komari-added-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="' + cfg.color +
      '" stroke-linecap="round" stroke-linejoin="round" style="flex-shrink:0;margin-right:6px;vertical-align:-3px;">' +
      cfg.svg + '</svg>';
  }
  // 精确排除：class 里同时含 text-base 和 font-bold 的，是图表标题，不加图标
  function isChartTitle(node){
    var cls = node.className || '';
    return typeof cls === 'string' && /text-base/.test(cls) && /font-bold/.test(cls);
  }
  function hasNativeIcon(node){
    var parent = node.parentElement;
    if (!parent) return false;
    var scopeParents = [parent, parent.parentElement].filter(Boolean);
    for (var p = 0; p < scopeParents.length; p++) {
      var svgs = scopeParents[p].querySelectorAll('svg');
      for (var i = 0; i < svgs.length; i++) {
        if (!svgs[i].classList.contains('komari-added-icon')) return true;
      }
    }
    return false;
  }
  function isWithinFreeCard(node){
    var el = node.parentElement;
    for (var i = 0; i < 10 && el; i++) {
      if (el.dataset && el.dataset.komariFreeCard === '1') return true;
      if (/免费/.test(el.textContent || '') && el.textContent.trim() !== '免费') {
        el.dataset.komariFreeCard = '1';
        return true;
      }
      el = el.parentElement;
    }
    return false;
  }

  function processNode(node){
    if (node.nodeType !== 1) return;
    if (node.classList && node.classList.contains('komari-icon-wrap')) return;
    if (node.children.length === 0) {
      var text = node.textContent.trim();
      if (ICONS[text]) {
        if (isChartTitle(node)) return;      // 图表标题：不加图标
        if (hasNativeIcon(node)) return;      // 已有原生图标：不重复加
        var wrap = document.createElement('span');
        wrap.className = 'komari-icon-wrap';
        wrap.style.cssText = 'display:inline-flex;align-items:center;white-space:nowrap;';
        wrap.innerHTML = makeIconHTML(ICONS[text]) + '<span>' + text + '</span>';
        node.innerHTML = '';
        node.appendChild(wrap);
        return;
      }
      if (FREE_PLAN_RE.test(text)) {
        node.textContent = '免费';
        return;
      }
      if (ZERO_PRICE_RE.test(text)) {
        if (isWithinFreeCard(node)) node.textContent = '免费';
        return;
      }
    } else {
      for (var i = 0; i < node.children.length; i++) processNode(node.children[i]);
    }
  }
  function run(){ processNode(document.body); }
  run();
  var scheduled = false;
  new MutationObserver(function(){
    if (scheduled) return;
    scheduled = true;
    setTimeout(function(){ scheduled = false; run(); }, 50);
  }).observe(document.body, { childList: true, subtree: true });
})();
</script>