// Synchronizes only website theme attributes; the website owns its layout.
// Origin checks keep login providers and other websites outside this adapter.
const WEB_ADAPTER_SCRIPT: string = `(function () {
  if (location.hostname !== 'www.tiktok.com' && location.hostname !== 'tiktok.com') {
    return 'unsupported-origin';
  }
  var theme = '__TK_NEXT_THEME__';
  var existing = window.__tiktokNextAppearance;
  if (existing) {
    existing.theme = theme;
    existing.apply();
    return theme;
  }
  var state = { theme: theme, installed: false };
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