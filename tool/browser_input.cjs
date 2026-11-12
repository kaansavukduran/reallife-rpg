const assert = require('node:assert/strict');

// Flutter's semantics DOM includes offscreen fields. Bring the actual Flutter
// viewport to the field before focusing its native editable input. A synthetic
// click() does not focus a newly inserted input after a dialog closes.
// Separate smoke routes keep semantics disabled and test Canvas mouse/touch.
async function focusField(locator) {
  const page = locator.page();
  await page.bringToFront();
  await page.waitForTimeout(250);
  const viewport = page.viewportSize();
  let box;
  for (let i = 0; i < 50; i++) {
    box = await locator.boundingBox();
    if (box && box.y >= 64 && box.y + box.height <= viewport.height - 120) break;
    assert.ok(box, 'The requested field is present');
    const delta = box.y < 64 ? box.y - 64 : box.y + box.height - (viewport.height - 120);
    await page.mouse.move(Math.max(20, Math.min(viewport.width - 20, box.x + box.width / 2)), viewport.height / 2);
    await page.mouse.wheel(0, Math.max(-240, Math.min(240, delta)));
    await page.waitForTimeout(100);
  }
  assert.ok(box && box.y >= 64 && box.y + box.height <= viewport.height - 120, 'The field is reachable in the Flutter viewport');
  const diagnostic = await locator.evaluate(element => ({
    target: element.getAttribute('aria-label'),
    before: {active: document.activeElement.tagName, label: document.activeElement.getAttribute('aria-label'), hasFocus: document.hasFocus(), visibility: document.visibilityState},
    lineage: [element, ...Array.from((function*(){let p=element.parentElement;while(p){yield p;p=p.parentElement;}})())].slice(0,10).map(e=>({tag:e.tagName,id:e.id,role:e.getAttribute('role'),inert:e.inert,hidden:e.getAttribute('aria-hidden'),display:getComputedStyle(e).display,visibility:getComputedStyle(e).visibility})),
    connected: element.isConnected, disabled: element.disabled, readOnly: element.readOnly,
  }));
  await page.evaluate(() => {
    if(window.__aioniaFocusEvents)return;
    window.__aioniaFocusEvents=[];
    for(const type of ['focusin','focusout']) document.addEventListener(type,event=>{
      window.__aioniaFocusEvents.push({type,t:performance.now(),tag:event.target.tagName,label:event.target.getAttribute?.('aria-label'),hasFocus:document.hasFocus()});
      if(window.__aioniaFocusEvents.length>20)window.__aioniaFocusEvents.shift();
    },true);
  });
  await locator.focus();
  diagnostic.instant = await locator.evaluate(element=>({owns:document.activeElement===element,active:document.activeElement.tagName,label:document.activeElement.getAttribute('aria-label'),connected:element.isConnected}));
  for (let i = 0; i < 60; i++) {
    if (await locator.evaluate(element => document.activeElement === element)) break;
    await page.waitForTimeout(50);
  }
  await page.waitForTimeout(250);
  const focus = await locator.evaluate(element => ({
    owns: document.activeElement === element,
    target: element.getAttribute('aria-label'),
    active: document.activeElement.getAttribute('aria-label'),
    activeTag: document.activeElement.tagName,
  }));
  if(!focus.owns || diagnostic.target?.startsWith('Duration')) console.log('FOCUS_DIAGNOSTIC',JSON.stringify({diagnostic,final:focus,events:await page.evaluate(()=>window.__aioniaFocusEvents)}));
  assert.equal(focus.owns, true, `Flutter field owns focus: ${JSON.stringify(focus)}`);
  return page;
}
async function typeText(locator, value) {
  const page = await focusField(locator);
  await page.keyboard.press('ControlOrMeta+A');
  await page.waitForTimeout(50);
  await page.keyboard.type(value, {delay: 35});
  await page.waitForTimeout(100);
  assert.equal(await locator.inputValue(), value, 'The requested field retains the typed value');
  await page.keyboard.press('Tab');
  await page.waitForTimeout(250);
}
module.exports = {typeText, focusField};
