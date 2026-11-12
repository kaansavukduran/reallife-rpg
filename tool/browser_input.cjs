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
  await locator.focus();
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
