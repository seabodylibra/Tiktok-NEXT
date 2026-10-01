// Uses TikTok's existing theme attributes and limits CSS overrides to narrow feed layouts.
// Origin checks keep login providers and other websites outside this adapter.
const WEB_ADAPTER_SCRIPT: string = `(function () {
  if (location.hostname !== 'www.tiktok.com' && location.hostname !== 'tiktok.com') {
    return 'unsupported-origin';
  }
  var theme = '__TK_NEXT_THEME__';
  var css = [
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
  };
  window.__tiktokNextAppearance = state;
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