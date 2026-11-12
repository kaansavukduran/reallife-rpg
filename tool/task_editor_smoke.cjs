const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {chromium} = require('playwright');
const {typeText, focusField} = require('./browser_input.cjs');

(async () => {
  const browser = await chromium.launch({executablePath: process.env.CHROMIUM_PATH || '/usr/bin/chromium', headless: true, args: ['--no-sandbox']});
  let diagnostic;
  const reflow = process.env.AIONIA_REFLOW === '1';
  const url = process.argv[2] || 'http://127.0.0.1:5173';
  const shots = path.resolve('docs/screenshots'); fs.mkdirSync(shots, {recursive: true});
  const errors = [], remote = [];
  const click = async (p, f) => {await f.evaluate(e => e.click()); await p.waitForTimeout(200);};
  const labels = p => p.locator('body').ariaSnapshot();
  const data = p => p.evaluate(() => JSON.parse(localStorage.getItem('reallife-rpg-data') || 'null'));
  const scrollTo = async (p, locator) => {
    for (let i = 0; i < 24; i++) {
      const b = await locator.count() ? await locator.boundingBox() : null;
      if (b && b.y > 70 && b.y + b.height < p.viewportSize().height - 140) return b;
      await p.mouse.move(p.viewportSize().width / 2, p.viewportSize().height / 2);
      await p.mouse.wheel(0, 240);
      await p.waitForTimeout(100);
    }
    throw new Error('Control was not reachable by scrolling');
  };
  try {
    for (const phone of [false, true]) {
      const context = await browser.newContext({locale: 'en-US', viewport: phone ? {width: 390, height: 844} : {width: 1440, height: 1100}, hasTouch: phone, isMobile: phone});
      await context.addInitScript(({phone,reflow}) => {
        if (!localStorage.getItem('reallife-rpg-settings')) localStorage.setItem('reallife-rpg-settings', JSON.stringify({language: 'en', game_mode: false, ui_scale: reflow ? 2 : 1, text_scale: phone && !reflow ? 2 : 1, display_mode: phone ? 'dark' : 'light', appearance: {reduce_motion: true}}));
      }, {phone,reflow});
      const p = await context.newPage(); diagnostic = p;
      p.on('pageerror', e => errors.push(String(e)));
      p.on('request', r => {if (new URL(r.url()).origin !== new URL(url).origin) remote.push(r.url());});
      await p.goto(url);await p.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
      await p.locator('flt-semantics-placeholder').evaluate(e => e.click());
      const newTaskBox = await p.getByRole('button', {name: 'New task', exact: true}).boundingBox();
      await click(p, p.getByRole('button', {name: 'New task', exact: true}));
      await click(p, p.getByRole('button', {name: 'Add', exact: true}));
      await p.getByText('Enter a task name.', {exact: true}).first().waitFor();
      assert.equal(await data(p), null);
      if (phone) await p.screenshot({path: path.join(shots, reflow?'aionia43-error-ui200.png':'task-editor-error-large-en.png')});
      const initialAddBox = await p.getByRole('button', {name: 'Add', exact: true}).boundingBox();
      const title = p.getByRole('textbox', {name: /Task name/});
      const b = await title.boundingBox();
      assert.ok(b && b.x >= 0 && b.x + b.width <= p.viewportSize().width + 1);
      // Accessibility focus plus real keystrokes is a separate route from the
      // Canvas pointer check below. Never inject text into app state/storage.
      // Leave the autofocus session, then return through a fresh semantics
      // focus action; DOM focus alone is not Flutter's input connection.
      await focusField(p.getByRole('textbox', {name: /Note/}));
      await p.waitForTimeout(250);
      await typeText(title, 'Read one page');
      await typeText(p.getByRole('textbox', {name: /Note/}), 'Kişisel not: özgün metin');
      await typeText(p.getByRole('textbox', {name: /Steps/}), 'First step\nİkinci adım');
      // Resize the actual browser view: this checks reflow/draft preservation,
      // not a physical OS keyboard or real-device certification.
      if (phone) {
        await p.setViewportSize({width: 844, height: 390});await p.waitForTimeout(250);
        // Resizing can recreate Flutter's native semantics input. Reconnect
        // focus before reading the controller; never retype the draft.
        await focusField(title);await p.waitForTimeout(300);
        assert.equal(await title.inputValue(), 'Read one page');
        await p.setViewportSize({width: 390, height: 600});await p.waitForTimeout(250);
        await focusField(p.getByRole('textbox',{name:/Note/}));await p.waitForTimeout(300);
        assert.equal(await p.getByRole('textbox', {name: /Note/}).inputValue(), 'Kişisel not: özgün metin');
        await p.setViewportSize({width: 390, height: 844});await p.waitForTimeout(200);
      }
      await click(p, p.getByRole('checkbox', {name: 'Selected days', exact: true}));
      for (const day of ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']) await click(p, p.getByRole('checkbox', {name: new RegExp('^' + day)}));
      await click(p, p.getByRole('button', {name: 'Add', exact: true}));
      assert.ok((await labels(p)).includes('Choose at least one day.'));
      assert.equal(await data(p), null);
      await click(p, p.getByRole('button', {name: 'Weekdays', exact: true}));
      assert.equal(await title.inputValue(), 'Read one page');
      await click(p, p.getByRole('button', {name: /^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday), /}));
      await p.getByRole('button', {name: 'Select', exact: true}).waitFor();
      if (reflow && phone) {
        const date = p.getByRole('textbox').last();
        await typeText(date, 'invalid');
        await click(p,p.getByRole('button',{name:'Select',exact:true}));
        assert.equal(await data(p), null);
        assert.ok((await labels(p)).includes('Invalid format.'));
      } else {
        assert.match(await labels(p), /January|February|March|April|May|June|July|August|September|October|November|December/);
      }
      await click(p, p.getByRole('button', {name: 'Cancel', exact: true}).last());
      // Flutter recreates native accessibility inputs when an overlay closes;
      // focus reattaches the editor's controller before reading its draft.
      await focusField(title);await p.waitForTimeout(300);
      assert.equal(await title.inputValue(), 'Read one page');
      const timeBox = await scrollTo(p,p.getByRole('button',{name:'Add time',exact:true}));
      await p.mouse.click(timeBox.x + timeBox.width / 2, timeBox.y + timeBox.height / 2);
      await p.getByRole('textbox', {name: /Hour/}).waitFor();
      if (phone) {
        await typeText(p.getByRole('textbox', {name: /Hour/}), '24');
        await typeText(p.getByRole('textbox', {name: /Minute/}), '60');
        await click(p, p.getByRole('button', {name: 'Select', exact: true}));
        assert.ok((await labels(p)).includes('Enter an hour from 00 to 23.'));
        await p.screenshot({path: path.join(shots, reflow?'aionia43-time-ui200.png':'task-time-error-large-en.png')});
        assert.equal(await data(p), null);
      }
      // Reconnect the input client from another text field before editing an
      // autofocus/Tab target. Keep the exact value and saved JSON assertions.
      await focusField(p.getByRole('textbox',{name:/Minute/}));await p.waitForTimeout(300);
      await typeText(p.getByRole('textbox', {name: /Hour/}), '23');
      await focusField(p.getByRole('textbox',{name:/Hour/}));await p.waitForTimeout(300);
      await typeText(p.getByRole('textbox', {name: /Minute/}), '45');
      await click(p, p.getByRole('button', {name: 'Select', exact: true}));
      const duration = p.getByRole('textbox', {name: /Duration \(min\)/});
      await typeText(duration, '0', {keyboard:true});
      await click(p, p.getByRole('button', {name: 'Add', exact: true}));
      assert.ok((await labels(p)).includes('Enter 1–1440 minutes or leave empty.'));
      assert.equal(await data(p), null);
      await focusField(p.getByRole('textbox',{name:/Steps/}));await p.waitForTimeout(300);
      await typeText(duration, '45', {keyboard:true});
      await click(p, p.getByRole('checkbox', {name: 'Every day', exact: true}));
      const pointerContext = await browser.newContext({locale: 'en-US', viewport: p.viewportSize(), hasTouch: phone, isMobile: phone});
      await pointerContext.addInitScript(({phone,reflow}) => localStorage.setItem('reallife-rpg-settings', JSON.stringify({language: 'en', game_mode: false, ui_scale: reflow ? 2 : 1, text_scale: phone && !reflow ? 2 : 1, display_mode: phone ? 'dark' : 'light', appearance: {reduce_motion: true}})), {phone,reflow});
      const pointer = await pointerContext.newPage();
      pointer.on('pageerror', e => errors.push(String(e)));
      pointer.on('request', r => {if (new URL(r.url()).origin !== new URL(url).origin) remote.push(r.url());});
      await pointer.goto(url);await pointer.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
      await pointer.waitForTimeout(1000);await pointer.bringToFront();
      const activate = async box => phone
        ? pointer.touchscreen.tap(box.x + box.width / 2, box.y + box.height / 2)
        : pointer.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      await activate(newTaskBox);await pointer.waitForTimeout(350);
      await pointer.keyboard.type('Canvas entry');await pointer.waitForTimeout(200);
      await activate(initialAddBox);
      await pointer.waitForFunction(() => JSON.parse(localStorage.getItem('reallife-rpg-data') || 'null')?.tasks?.length === 1);
      assert.equal((await data(pointer)).tasks[0].title, 'Canvas entry');
      assert.equal((await data(pointer)).completions.length, 0);
      await pointerContext.close();await p.bringToFront();
      console.log(`PASS task editor: physical Canvas ${phone ? 'touch' : 'mouse'} and keyboard create a saved task`);
      const name = reflow ? (phone?'aionia43-phone-ui200.png':'aionia43-desktop-ui200.png') : (phone ? 'task-editor-phone-large-en.png' : 'task-editor-desktop-en.png');
      await p.screenshot({path: path.join(shots, name)});
      await click(p, p.getByRole('button', {name: 'Add', exact: true}));
      await p.waitForFunction(() => JSON.parse(localStorage.getItem('reallife-rpg-data') || 'null')?.tasks?.length === 1);
      const saved = (await data(p)).tasks[0];
      assert.equal(saved.title, 'Read one page');assert.equal(saved.note, 'Kişisel not: özgün metin');
      assert.deepEqual(saved.steps.map(s => s.title), ['First step', 'İkinci adım']);
      assert.equal(saved.time, '23:45');assert.equal(saved.duration_minutes, 45);
      assert.equal((await data(p)).completions.length, 0);
      const edit = p.getByRole('button', {name: /Read one page.*To do.*open to edit/s});
      await scrollTo(p, edit);
      await click(p, edit);
      await typeText(p.getByRole('textbox', {name: /Task name/}), 'Do not save this draft');
      await click(p, p.getByRole('button', {name: 'Cancel', exact: true}));
      assert.deepEqual((await data(p)).tasks[0], saved);
      await p.reload();await p.waitForFunction(() => document.querySelector('flt-semantics-placeholder'));
      assert.deepEqual((await data(p)).tasks[0], saved);
      await p.locator('flt-semantics-placeholder').evaluate(e=>e.click());
      await scrollTo(p,p.getByRole('button',{name:/Read one page.*To do.*open to edit/s}));
      if(reflow) {
        assert.equal(await p.evaluate(()=>JSON.parse(localStorage.getItem('reallife-rpg-settings')).ui_scale),2);
        const box=await p.getByRole('button',{name:/Read one page.*To do.*open to edit/s}).boundingBox();
        assert.ok(box.x>=0 && box.x+box.width<=p.viewportSize().width+1,'task reflows within the viewport at unchanged 200% UI');
      }
      console.log(`PASS task editor: English labels/date/time, field errors, real ${phone ? (reflow?'touch + 200% UI, resize':'touch + 200% text, resize') : 'mouse'}/keyboard, cancel, Unicode data, no automatic XP/completions and reload (phone=${phone}, real UI200=${reflow})`);
      await context.close();
    }
    assert.deepEqual(errors, []);assert.deepEqual(remote, []);
    console.log('PASS task editor: no uncaught browser errors or remote-origin requests in tested flows');
  } catch (e) {
    if (diagnostic) fs.writeFileSync(path.join(shots, 'task-editor-failure-aria.txt'), await diagnostic.locator('body').ariaSnapshot());
    if (diagnostic) await diagnostic.screenshot({path: path.join(shots, 'task-editor-failure.png')}).catch(() => {});
    throw e;
  } finally {await browser.close();}
})().catch(e => {console.error(e);process.exit(1);});
