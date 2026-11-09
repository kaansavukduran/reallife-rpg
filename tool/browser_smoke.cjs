const {openMenu}=require('./browser_menu.cjs');
// Development-only check. Requires Playwright and a local Chromium installation.
// Serve `build/web`, then: node tool/browser_smoke.cjs [http://127.0.0.1:5173]
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { chromium } = require('playwright');

const {typeText} = require('./browser_input.cjs');
(async () => {
  const temporary = fs.mkdtempSync(path.join(os.tmpdir(), 'reallife-browser-'));
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || '/usr/bin/chromium',
    headless: true,
    args: ['--no-sandbox'],
  });
  let diagnosticPage;
  try {
    const context = await browser.newContext({locale: 'tr-TR', viewport: {width: 1440, height: 1050}, acceptDownloads: true});
    const page = await context.newPage();
    diagnosticPage = page;
    page.setDefaultTimeout(15000);
    const errors = [];
    page.on('pageerror', error => errors.push(String(error)));
    await page.goto(process.argv[2] || 'http://127.0.0.1:5173');
    await page.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
    await page.waitForTimeout(1500); // Finite companion entrance.
    const screenshots = path.resolve('docs/screenshots');
    fs.mkdirSync(screenshots, {recursive: true});
    await page.screenshot({path: path.join(screenshots, 'adventure-desktop.png')});
    await page.setViewportSize({width: 390, height: 844});
    await page.waitForTimeout(300);
    await page.screenshot({path: path.join(screenshots, 'adventure-mobile.png')});
    await page.setViewportSize({width: 1440, height: 1050});
    await page.locator('flt-semantics-placeholder').evaluate(element => element.click());
    assert.equal(await page.getByText('Odak', {exact:true}).count(),0);
    assert.equal(await page.getByText('Yaşam atlası', {exact:true}).count(),0);
    const navOrigin=await page.getByText('Maceram',{exact:true}).boundingBox();
    const navTarget=await page.getByText('Gün',{exact:true}).boundingBox();
    const pinnedSettings=await page.getByText('Ayarlar',{exact:true}).boundingBox();
    assert.ok(navOrigin && navTarget && pinnedSettings);
    await page.mouse.move(navOrigin.x+30,navOrigin.y+navOrigin.height/2);
    await page.mouse.down();
    for(let i=1;i<=12;i++){
      await page.mouse.move(navOrigin.x+30,navOrigin.y+navOrigin.height/2+
        (navTarget.y+navTarget.height/2+20-navOrigin.y-navOrigin.height/2)*i/12);
      await page.waitForTimeout(40);
    }
    await page.mouse.up();
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-settings')||'{}').navigation_order?.[0]==='gun');
    assert.deepEqual(await page.getByText('Ayarlar',{exact:true}).boundingBox(),pinnedSettings);
    await page.screenshot({path:path.join(screenshots,'menu-custom-order.png')});
    await page.reload();await page.waitForFunction(()=>document.querySelector('flt-semantics-placeholder'));
    await page.locator('flt-semantics-placeholder').evaluate(e=>e.click());
    assert.equal(await page.evaluate(()=>JSON.parse(localStorage.getItem('reallife-rpg-settings')).navigation_order[0]),'gun');
    const resetMenu=page.getByRole('button',{name:'Menü sırasını sıfırla',exact:true});
    for(let i=0;i<8 && await resetMenu.count()===0;i++){
      await page.mouse.move(110,650);await page.mouse.wheel(0,350);await page.waitForTimeout(150);
    }
    await resetMenu.evaluate(e=>e.click());
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-settings')).navigation_order[0]==='maceram');
    assert.equal(await page.evaluate(()=>localStorage.getItem('reallife-rpg-data')),null);
    await page.reload();await page.waitForFunction(()=>document.querySelector('flt-semantics-placeholder'));
    await page.locator('flt-semantics-placeholder').evaluate(e=>e.click());
    console.log('STEP: real menu drag, fixed Settings, restart/reset and removed pages passed');
    await openMenu(page,'Sağlık');
    await page.getByRole('button', {name: 'Bir bardak su ekle'}).click();
    await openMenu(page,'Maceram');
    await page.getByRole('button', {name: 'Yeni görev', exact: true}).click();
    await typeText(page.getByRole('textbox', {name: /Görev adı/}), 'Bir sayfa öğren');
    await page.getByRole('button', {name: 'Ekle', exact: true}).evaluate(el => el.click());
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.tasks?.length===1);
    await openMenu(page,'Gün');
    await page.getByRole('checkbox', {name: /Bir sayfa öğren/}).click();
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.completions?.length===1);
    console.log('STEP: day completion persisted');
    await openMenu(page,'Görevler');
    const taskCheck = page.getByRole('checkbox', {name: /Bir sayfa öğren.*Yapıldı/});
    assert.equal(await taskCheck.getAttribute('aria-checked'), 'true');
    const checkBox = await taskCheck.boundingBox();
    const tasksLink = await page.getByText('Görevler', {exact: true}).boundingBox();
    // Same clean test context shares the task made through the UI. Semantics
    // stay disabled on this page: these are actual Canvas mouse events.
    const taskPointer = await page.context().newPage();
    await taskPointer.setViewportSize({width:1440,height:1050});
    taskPointer.on('pageerror', error => errors.push(String(error)));
    await taskPointer.goto(process.argv[2] || 'http://127.0.0.1:5173');
    await taskPointer.waitForFunction(()=>document.querySelector('flt-semantics-placeholder'));
    await taskPointer.waitForTimeout(700);
    await taskPointer.mouse.click(tasksLink.x+tasksLink.width/2,tasksLink.y+tasksLink.height/2);
    await taskPointer.waitForTimeout(300);
    await taskPointer.mouse.click(checkBox.x+checkBox.width/2,checkBox.y+checkBox.height/2);
    await taskPointer.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.completions?.length===0);
    await taskPointer.mouse.click(checkBox.x+checkBox.width/2,checkBox.y+checkBox.height/2);
    await taskPointer.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')||'null')?.completions?.length===1);
    await taskPointer.screenshot({path:path.join(screenshots,'tasks-direct-completion.png')});
    await taskPointer.reload();
    await taskPointer.waitForFunction(()=>document.querySelector('flt-semantics-placeholder'));
    assert.equal(await taskPointer.evaluate(()=>JSON.parse(localStorage.getItem('reallife-rpg-data')).completions.length),1);
    console.log('STEP: Canvas task toggles and restart passed');
    await taskPointer.close();
    await page.bringToFront();
    await openMenu(page,'Ayarlar');
    // Flutter's accessible slider uses a native range with normalized 0/1/2
    // increment actions. Test ordinary mouse dragging in a fresh page with
    // semantics disabled, using geometry from the identical accessible layout.
    const track = await page.locator('[flt-semantics-identifier="interface-scale-track"]').boundingBox();
    const settingsLink = await page.getByText('Ayarlar', {exact: true}).boundingBox();
    assert.ok(track && settingsLink, 'Scale bar and settings navigation are visible');
    const pointerPage = await browser.newPage({locale: 'tr-TR', viewport: {width: 1440, height: 1050}});
    pointerPage.on('pageerror', error => errors.push(String(error)));
    await pointerPage.goto(process.argv[2] || 'http://127.0.0.1:5173');
    await pointerPage.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
    await pointerPage.waitForTimeout(1500);
    await pointerPage.mouse.click(settingsLink.x + settingsLink.width / 2, settingsLink.y + settingsLink.height / 2);
    await pointerPage.waitForTimeout(350);
    const trackX = fraction => track.x + 24 + (track.width - 48) * fraction;
    await pointerPage.mouse.move(trackX(20 / 120), track.y + track.height / 2);
    await pointerPage.mouse.down();
    await pointerPage.mouse.move(trackX(92 / 120), track.y + track.height / 2, {steps: 12});
    await pointerPage.waitForTimeout(150);
    await pointerPage.mouse.move(trackX(57 / 120), track.y + track.height / 2, {steps: 12});
    await pointerPage.waitForTimeout(150);
    assert.equal(await pointerPage.evaluate(() => JSON.parse(localStorage.getItem('reallife-rpg-settings') || '{}').ui_scale ?? 1), 1);
    await pointerPage.mouse.up();
    await pointerPage.waitForFunction(()=>{const s=JSON.parse(localStorage.getItem('reallife-rpg-settings')||'null');return s?.ui_scale>1.2&&s.ui_scale<1.55;});
    const savedScale = await pointerPage.evaluate(() => JSON.parse(localStorage.getItem('reallife-rpg-settings')).ui_scale);
    assert.ok(savedScale > 1.2 && savedScale < 1.55, `Dragged scale: ${savedScale}`);
    assert.ok(![1, 1.25, 1.5, 1.75, 2].includes(savedScale));
    await pointerPage.screenshot({path: path.join(screenshots, 'interface-scale-slider.png')});
    await pointerPage.reload();
    await pointerPage.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
    assert.equal(await pointerPage.evaluate(() => JSON.parse(localStorage.getItem('reallife-rpg-settings')).ui_scale), savedScale);
    console.log('STEP: Canvas scale and restart passed');
    await pointerPage.close();
    await page.bringToFront();
    const reveal = async locator => {
      for (let attempt = 0; attempt < 20; attempt++) {
        const box = await locator.count() ? await locator.boundingBox() : null;
        if (box && box.y >= 100 && box.y + box.height < 970) return;
        await page.mouse.move(1100, 750);
        await page.mouse.wheel(0, box && box.y < 100 ? -300 : 300);
        await page.waitForTimeout(200);
      }
      throw new Error('Settings control could not be reached');
    };
    await reveal(page.getByRole('button', {name: /^Vurgu rengi\s*#/}));
    // Activate the Flutter semantic action; the row also contains a separate reset control.
    await page.getByRole('button', {name: /^Vurgu rengi\s*#/}).evaluate(element => element.click());
    await typeText(page.getByRole('textbox', {name: /HEX renk kodu/}), '7C5CFC');
    await page.waitForTimeout(150);
    await page.screenshot({path: path.join(screenshots, 'color-picker.png')});
    await page.getByRole('button', {name: 'Rengi uygula', exact: true}).evaluate(element => element.click());
    await page.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-settings')||'null')?.appearance?.primary===0xff7c5cfc);
    console.log('STEP: HEX persisted');
    const appearance = await page.evaluate(() => JSON.parse(localStorage.getItem('reallife-rpg-settings')).appearance);
    assert.equal(appearance.primary, 0xff7c5cfc);
    await page.screenshot({path: path.join(screenshots, 'custom-theme-desktop.png')});
    await reveal(page.getByRole('button', {name: 'Yedeği dışa aktar'}));
    const [download] = await Promise.all([page.waitForEvent('download'), page.getByRole('button', {name: 'Yedeği dışa aktar'}).press('Enter')]);
    const backup = path.join(temporary, 'backup.json');
    await download.saveAs(backup);
    const exported = JSON.parse(fs.readFileSync(backup, 'utf8'));
    assert.equal(exported.completions.length, 1);
    assert.equal(Object.values(exported.life.health)[0].water, 1);
    console.log('STEP: export verified');
    const [chooser] = await Promise.all([page.waitForEvent('filechooser'), page.getByRole('button', {name: 'Yedeği içe aktar'}).press('Enter')]);
    await chooser.setFiles(backup);
    console.log('STEP: file chooser received backup');
    await page.getByText(/^Seçilen JSON yedeği/).click();
    await page.getByRole('button', {name: 'Yükle', exact: true}).click();
    await page.waitForFunction(()=>{const d=JSON.parse(localStorage.getItem('reallife-rpg-data')||'null');return d?.tasks?.length===1&&d?.completions?.length===1;});
    await page.reload();
    await page.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
    const restored = await page.evaluate(() => JSON.parse(localStorage.getItem('reallife-rpg-data')));
    assert.equal(restored.tasks[0].title, 'Bir sayfa öğren');
    assert.equal(restored.completions.length, 1);
    assert.equal(await page.evaluate(() => JSON.parse(localStorage.getItem('reallife-rpg-settings')).appearance.primary), 0xff7c5cfc);
    assert.equal(Object.values(restored.life.health)[0].water, 1);
    assert.deepEqual(errors, []);
    console.log('PASS: desktop/mobile render, health record, task create/complete, mouse scale dragging, HEX theme customization, JSON export/import, restart persistence; no browser errors.');
  } catch (error) {
    // Only this newly created synthetic test context is captured.
    if (diagnosticPage && !diagnosticPage.isClosed()) {
      await diagnosticPage.screenshot({path: path.resolve('docs/screenshots/browser-failure.png')});
      console.log('BROWSER_FAILURE', await diagnosticPage.locator('body').innerText());
    }
    throw error;
  } finally {
    await browser.close();
    fs.rmSync(temporary, {recursive: true, force: true});
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
