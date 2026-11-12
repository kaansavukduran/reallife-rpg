const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {chromium}=require('playwright');
const {typeText}=require('./browser_input.cjs');
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',headless:true,args:['--no-sandbox']});
 const context=await browser.newContext({locale:'en-US',colorScheme:'light',viewport:{width:390,height:844},hasTouch:true,isMobile:true});
 const p=await context.newPage();const url=process.argv[2]||'http://127.0.0.1:5173';const errors=[],remote=[];
 p.on('pageerror',e=>errors.push(String(e)));p.on('request',r=>{if(new URL(r.url()).origin!==new URL(url).origin)remote.push(r.url());});
 const shots=path.resolve('docs/screenshots');fs.mkdirSync(shots,{recursive:true});
 async function visible(locator){for(let i=0;i<40;i++){const b=await locator.count()?await locator.boundingBox():null;if(b&&b.y>80&&b.y+b.height<760)return b;await p.mouse.move(200,500);await p.mouse.wheel(0,250);await p.waitForTimeout(100);}throw Error('Control unreachable');}
 try {
  await p.goto(url);await p.waitForFunction(()=>document.querySelector('flt-semantics-placeholder'));
  await p.locator('flt-semantics-placeholder').evaluate(e=>e.click());await p.waitForTimeout(1500);
  assert.equal(await p.evaluate(()=>localStorage.getItem('reallife-rpg-data')),null);
  await p.screenshot({path:path.join(shots,'aionia43-default-dark-phone.png')});
  const menu=await p.getByRole('button',{name:'Open navigation menu',exact:true}).boundingBox();
  await p.touchscreen.tap(menu.x+menu.width/2,menu.y+menu.height/2);await p.waitForTimeout(250);
  const settings=await p.getByText('Settings',{exact:true}).last().boundingBox();
  await p.touchscreen.tap(settings.x+settings.width/2,settings.y+settings.height/2);await p.waitForTimeout(250);
  const percent=p.getByRole('textbox',{name:/Percentage/});await visible(percent);await typeText(percent,'200');
  const apply=await visible(p.getByRole('button',{name:'Apply percentage',exact:true}));
  await p.touchscreen.tap(apply.x+apply.width/2,apply.y+apply.height/2);
  await p.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-settings')||'null')?.ui_scale===2);
  const prefs=await p.evaluate(()=>JSON.parse(localStorage.getItem('reallife-rpg-settings')));
  assert.equal(prefs.display_mode,'dark');assert.equal(prefs.appearance.font,'system');
  assert.equal(await p.evaluate(()=>localStorage.getItem('reallife-rpg-data')),null);
  await visible(percent);await p.screenshot({path:path.join(shots,'aionia43-settings-ui200.png')});
  const reset=p.getByRole('button',{name:'Reset to default size (100%)',exact:true});const b=await visible(reset);
  await p.touchscreen.tap(b.x+b.width/2,b.y+b.height/2);
  await p.waitForFunction(()=>JSON.parse(localStorage.getItem('reallife-rpg-settings')||'null')?.ui_scale===1);
  await p.reload();await p.waitForFunction(()=>document.querySelector('flt-semantics-placeholder'));await p.locator('flt-semantics-placeholder').evaluate(e=>e.click());
  await p.getByRole('button',{name:'New task',exact:true}).waitFor();
  assert.equal(await p.evaluate(()=>JSON.parse(localStorage.getItem('reallife-rpg-settings')).display_mode),'dark');
  assert.equal(await p.evaluate(()=>localStorage.getItem('reallife-rpg-data')),null);
  assert.deepEqual(errors,[]);assert.deepEqual(remote,[]);
  console.log('PASS defaults: fresh OS-light browser keeps dark/system defaults; real touch opens Settings, applies 200%, reaches/reset 100%, reload retains preferences; no personal data/XP fabricated or remote requests');
 }catch(e){fs.writeFileSync(path.join(shots,'defaults-failure-aria.txt'),await p.locator('body').ariaSnapshot());await p.screenshot({path:path.join(shots,'defaults-failure.png')});throw e;}
 finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1);});
