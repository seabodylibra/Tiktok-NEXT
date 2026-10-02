// Uses TikTok's existing theme attributes and limits CSS overrides to narrow feed layouts.
// Origin checks keep login providers and other websites outside this adapter.
const WEB_ADAPTER_SCRIPT: string = `(function () {
  if (location.hostname !== 'www.tiktok.com' && location.hostname !== 'tiktok.com') {
    return 'unsupported-origin';
  }
  var theme = '__TK_NEXT_THEME__';
  var css = [
    '@media (max-width: 600px) and (orientation: portrait) {',
    'html[data-tk-compact="true"] [class*="DivSideNavPlaceholderContainer"], html[data-tk-compact="true"] [class*="DivSideNavContainer"] { display:none!important; }',
    'html[data-tk-compact="true"] main[class*="DivMainContainer"] { width:100%!important; margin:0!important; padding:0 0 56px!important; min-width:0!important; }',
    'html[data-tk-compact="true"] [class*="ArticleItemContainer"] { height:calc(100dvh - 56px)!important; min-height:0!important; padding:0!important; margin:0!important; }',
    'html[data-tk-compact="true"] [class*="DivContentFlexLayout"] { position:relative!important; height:100%!important; gap:0!important; }',
    'html[data-tk-compact="true"] [class*="DivCardWrapper"] { width:100%!important; max-width:100%!important; height:100%!important; flex:1!important; align-self:stretch!important; }',
    'html[data-tk-compact="true"] [class*="SectionMediaCardContainer"] { height:100%!important; width:100%!important; max-height:none!important; border-radius:0!important; background:#000!important; }',
    'html[data-tk-compact="true"] [data-e2e="feed-video"] { height:100%!important; width:100%!important; }',
    'html[data-tk-compact="true"] video { width:100%!important; height:100%!important; object-fit:contain!important; }',
    'html[data-tk-compact="true"] [class*="SectionActionBarContainer"] { position:absolute!important; right:8px!important; bottom:76px!important; z-index:10!important; width:44px!important; max-width:44px!important; color:white!important; text-shadow:0 1px 3px #000!important; }',
    'html[data-tk-compact="true"] [class*="SectionActionBarContainer"] button { background:rgba(20,20,20,.5)!important; color:white!important; }',
    'html[data-tk-compact="true"] #tiktok-next-dock { display:flex!important; }',
    '}',
    '#tiktok-next-dock { display:none; position:fixed; bottom:0; left:0; right:0; height:56px; z-index:100; background:var(--ui-page-flat-1,white); align-items:center; justify-content:space-evenly; padding-left:54px; box-sizing:border-box; }',
    '#tiktok-next-dock button { border:0; background:transparent; color:var(--ui-text-1,black); font:600 13px sans-serif; padding:12px 8px; }',
    '@media (max-width: 600px) {',
    'main[class*="DivMainContainer"] { min-width: 0 !important; }',
    'main[class*="DivMainContainer"] [class*="DivColumnListContainer"],',
    'main[class*="DivMainContainer"] [class*="ArticleItemContainer"] {',
    '  min-width: 0 !important; max-width: 100% !important; width: 100% !important; box-sizing: border-box !important;',
    '}',
    'main[class*="DivMainContainer"] [class*="DivContentFlexLayout"] {',
    '  min-width: 0 !important; max-width: 100% !important; width: 100% !important; gap: 8px !important;',
    '}',
    'main[class*="DivMainContainer"] [class*="DivCardWrapper"] {',
    '  min-width: 0 !important; max-width: calc(100% - 48px) !important; flex: 1 1 0 !important;',
    '}',
    'main[class*="DivMainContainer"] [class*="SectionActionBarContainer"] {',
    '  flex: 0 0 40px !important; min-width: 40px !important; max-width: 40px !important;',
    '}',
    'main[class*="DivMainContainer"] [class*="SectionMediaCardContainer"],',
    'main[class*="DivMainContainer"] [data-e2e="feed-video"] { min-width: 0 !important; max-width: 100% !important; }',
    '}'
  ].join('\\n');

  var existing = window.__tiktokNextAppearance;
  if (existing) {
    existing.theme = theme;
    existing.apply();
    return theme;
  }
  var state = { theme: theme, installed: false };
  function ensureStyle() {
    if (!document.head || document.getElementById('tiktok-next-layout')) {
      return;
    }
    var style = document.createElement('style');
    style.id = 'tiktok-next-layout';
    style.textContent = css;
    document.head.appendChild(style);
  }
  state.apply = function () {
    var root = document.documentElement;
    if (!root) {
      return;
    }
    ['data-theme', 'data-tux-color-scheme'].forEach(function (attribute) {
      if (root.getAttribute(attribute) !== state.theme) {
        root.setAttribute(attribute, state.theme);
      }
    });
    root.style.colorScheme = state.theme;
    ensureStyle();
    var compactRoute = location.pathname === '/' || location.pathname === '/foryou';
    root.setAttribute('data-tk-compact', compactRoute ? 'true' : 'false');
    if (document.body && !document.getElementById('tiktok-next-dock')) {
      var dock = document.createElement('nav');
      dock.id = 'tiktok-next-dock';
      dock.setAttribute('aria-label', 'TikTok navigation');
      [['首页', '/'], ['探索', '/explore'], ['关注', '/following']].forEach(function (item) {
        var button = document.createElement('button');
        button.textContent = item[0];
        button.onclick = function () {
          var link = Array.from(document.querySelectorAll('a[href]')).find(function (a) {
            return a.origin === location.origin && a.pathname === item[1];
          });
          if (link) link.click(); else location.assign(item[1]);
        };
        dock.appendChild(button);
      });
      document.body.appendChild(dock);
    }
  };
  window.__tiktokNextAppearance = state;
  window.setInterval(function () { state.apply(); }, 1000);
  function install() {
    if (!document.documentElement || state.installed) {
      return;
    }
    state.installed = true;
    state.apply();
    var observer = new MutationObserver(state.apply);
    observer.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ['data-theme', 'data-tux-color-scheme']
    });
  }
  if (document.documentElement) {
    install();
  } else {
    var rootObserver = new MutationObserver(function () {
      if (document.documentElement) {
        rootObserver.disconnect();
        install();
      }
    });
    rootObserver.observe(document, { childList: true });
  }
  document.addEventListener('DOMContentLoaded', function () {
    install();
    state.apply();
  }, { once: true });
  return theme;
})()`;

export function createWebAdapterScript(isDark: boolean): string {
  return WEB_ADAPTER_SCRIPT.replace('__TK_NEXT_THEME__', isDark ? 'dark' : 'light');
}