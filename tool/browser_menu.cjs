// The reorderable sidebar lazily builds rows. Reach them through actual wheel
// scrolling; don't assume offscreen menu items already exist in the DOM.
async function openMenu(page, label) {
  const item=page.getByText(label,{exact:true});
  const settings=page.getByText(/^(Ayarlar|Settings)$/);
  for(let attempt=0;attempt<16;attempt++) {
    const box=await item.count()===1?await item.boundingBox():null;
    const footer=await settings.boundingBox();
    const limit=/^(Ayarlar|Settings)$/.test(label)?page.viewportSize().height:
      (footer?.y||page.viewportSize().height);
    if(box && box.y>=56 && box.y+box.height<=limit) {
      await item.evaluate(e=>e.click());await page.waitForTimeout(200);return;
    }
    await page.mouse.move(110,500);
    await page.mouse.wheel(0,attempt===0?-4000:250);
    await page.waitForTimeout(150);
  }
  throw new Error('Menu item unreachable: '+label);
}
module.exports={openMenu};
