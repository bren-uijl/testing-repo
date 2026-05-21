const { app, BrowserWindow, nativeImage } = require('electron');
const path = require('path');
const fs = require('fs');

const screenshotDir = path.join(__dirname, '..', 'screenshots');
if (!fs.existsSync(screenshotDir)) {
  fs.mkdirSync(screenshotDir, { recursive: true });
}

async function captureScreenshot(win, name) {
  await new Promise(resolve => setTimeout(resolve, 1500));
  const image = await win.webContents.capturePage();
  const buffer = image.toPNG();
  fs.writeFileSync(path.join(screenshotDir, `${name}.png`), buffer);
  console.log(`Saved ${name}.png`);
}

app.whenReady().then(async () => {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    show: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      webviewTag: true,
      experimentalFeatures: true,
      preload: path.join(__dirname, '..', 'src', 'preload.js'),
    },
  });

  // Screenshot 1: Homepage
  win.loadFile(path.join(__dirname, '..', 'src', 'ui', 'browser.html'));
  await captureScreenshot(win, 'browser-homepage');

  // Screenshot 2: Navigate to example.com
  win.webContents.executeJavaScript(`
    (async () => {
      const urlBar = document.querySelector('.url-bar input') || document.querySelector('input[type="text"]');
      if (urlBar) {
        urlBar.value = 'https://example.com';
        urlBar.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter' }));
      }
    })();
  `).catch(() => {});
  await new Promise(resolve => setTimeout(resolve, 3000));
  await captureScreenshot(win, 'browser-loaded-page');

  // Screenshot 3: Open settings
  const settingsWin = new BrowserWindow({
    width: 900,
    height: 700,
    show: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, '..', 'src', 'preload.js'),
    },
  });
  settingsWin.loadFile(path.join(__dirname, '..', 'src', 'ui', 'settings.html'));
  await captureScreenshot(settingsWin, 'browser-settings');

  app.quit();
});
