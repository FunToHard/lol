const { chromium } = require('playwright');
const path = require('path');

async function main() {
  const browser = await chromium.launch();
  const page = await browser.newPage({
    viewport: { width: 1200, height: 1600 }
  });

  const htmlPath = 'file:///' + path.resolve(__dirname, '../assets/preview/index.html').replace(/\\/g, '/');
  console.log('Loading:', htmlPath);
  await page.goto(htmlPath, { waitUntil: 'networkidle' });

  const outPath = path.resolve(__dirname, '../assets/preview/preview_screenshot.png');
  await page.screenshot({ path: outPath, fullPage: true });
  console.log('Saved screenshot to:', outPath);

  await browser.close();
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
