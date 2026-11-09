const assert = require('node:assert/strict');

// These form checks use Flutter's accessibility focus action. Physical Canvas
// keyboard/pointer interaction is covered separately by progress_smoke.cjs.
async function typeText(locator, value) {
  const page = locator.page();
  await page.bringToFront();
  await locator.evaluate(element => element.click());
  // The focus semantics action reaches Dart asynchronously. DOM focus alone
  // is earlier than the engine attaching its text-input event handlers.
  await page.waitForTimeout(250);
  assert.equal(await locator.evaluate(element => document.activeElement === element), true, 'Flutter field owns focus');
  await page.keyboard.press('ControlOrMeta+A');
  await page.waitForTimeout(50);
  await page.keyboard.type(value, {delay: 35});
  await page.waitForTimeout(100);
  assert.equal(await locator.inputValue(), value, 'The requested field retains the typed value');
  await page.keyboard.press('Tab');
}
module.exports = {typeText};
