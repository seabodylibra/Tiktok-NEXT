import { webview } from '@kit.ArkWeb';

// Let ArkWeb retain cookie attributes, expiry and HttpOnly protection.
export function configureWebSession(): void {
  webview.WebCookieManager.putAcceptCookieEnabled(true);
  webview.WebCookieManager.putAcceptThirdPartyCookieEnabled(true);
}

let saving: boolean = false;
export function saveWebSession(): void {
  if (saving) { return; }
  saving = true;
  try {
    webview.WebCookieManager.saveCookieAsync()
      .catch(() => { console.warn('Unable to persist web cookies.'); })
      .finally(() => { saving = false; });
  } catch {
    saving = false;
    console.warn('Unable to persist web cookies.');
  }
}
