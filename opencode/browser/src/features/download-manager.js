const fs = require('fs');
const path = require('path');
const { shell } = require('electron');

class DownloadManager {
  constructor(mainWindow, downloadsPath) {
    this.mainWindow = mainWindow;
    this.downloadsPath = downloadsPath;
    this.downloads = new Map();
    this.downloadCounter = 0;
    this.settingsPath = path.join(require('electron').app.getPath('userData'), 'download-settings.json');

    this.settings = {
      askDownloadPath: false,
      defaultPath: downloadsPath,
    };

    this.loadSettings();
    this.setupDownloadDir();
  }

  setupDownloadDir() {
    if (!fs.existsSync(this.downloadsPath)) {
      fs.mkdirSync(this.downloadsPath, { recursive: true });
    }
  }

  loadSettings() {
    try {
      if (fs.existsSync(this.settingsPath)) {
        this.settings = { ...this.settings, ...JSON.parse(fs.readFileSync(this.settingsPath, 'utf8')) };
      }
    } catch (err) {
      console.error('Failed to load download settings:', err);
    }
  }

  saveSettings(additionalSettings = {}) {
    this.settings = { ...this.settings, ...additionalSettings };
    try {
      fs.writeFileSync(this.settingsPath, JSON.stringify(this.settings, null, 2));
    } catch (err) {
      console.error('Failed to save download settings:', err);
    }
  }

  registerDownload(webContents, downloadItem) {
    const downloadId = `dl_${++this.downloadCounter}`;
    const filename = downloadItem.getFilename();
    const savePath = path.join(this.downloadsPath, filename);

    const downloadInfo = {
      id: downloadId,
      filename,
      url: downloadItem.getURL(),
      savePath,
      state: 'progressing',
      receivedBytes: 0,
      totalBytes: downloadItem.getTotalBytes(),
      startTime: Date.now(),
      endTime: null,
      error: null,
      progress: 0,
    };

    this.downloads.set(downloadId, downloadInfo);

    if (this.settings.askDownloadPath) {
      const result = require('electron').dialog.showSaveDialogSync(this.mainWindow, {
        title: 'Save Download',
        defaultPath: savePath,
      });
      if (result && !result.canceled && result.filePath) {
        downloadItem.setSavePath(result.filePath);
        downloadInfo.savePath = result.filePath;
      } else {
        downloadItem.setSavePath(savePath);
      }
    } else {
      downloadItem.setSavePath(savePath);
    }

    downloadItem.on('updated', (event, state) => {
      downloadInfo.state = state;
      downloadInfo.receivedBytes = downloadItem.getReceivedBytes();
      downloadInfo.totalBytes = downloadItem.getTotalBytes();
      downloadInfo.progress = downloadInfo.totalBytes > 0
        ? Math.round((downloadInfo.receivedBytes / downloadInfo.totalBytes) * 100)
        : 0;

      if (state === 'interrupted') {
        downloadInfo.state = 'paused';
      }

      this.notifyProgress(downloadId, downloadInfo);
    });

    downloadItem.on('done', (event, state) => {
      downloadInfo.state = state === 'completed' ? 'completed' : 'cancelled';
      downloadInfo.endTime = Date.now();
      downloadInfo.receivedBytes = downloadItem.getReceivedBytes();
      downloadInfo.progress = state === 'completed' ? 100 : downloadInfo.progress;

      if (state === 'completed') {
        downloadInfo.completedTime = Date.now();
        this.notifyComplete(downloadId, downloadInfo);
      } else {
        downloadInfo.error = 'Download cancelled';
        this.notifyError(downloadId, downloadInfo);
      }
    });

    this.notifyStart(downloadId, downloadInfo);

    return downloadId;
  }

  getDownloads() {
    return Array.from(this.downloads.values())
      .sort((a, b) => b.startTime - a.startTime)
      .map(d => ({
        ...d,
        progress: d.totalBytes > 0 ? Math.round((d.receivedBytes / d.totalBytes) * 100) : 0,
      }));
  }

  pauseDownload(downloadId) {
    const download = this.downloads.get(downloadId);
    if (download && download.state === 'progressing') {
      download.state = 'paused';
      return true;
    }
    return false;
  }

  resumeDownload(downloadId) {
    const download = this.downloads.get(downloadId);
    if (download && download.state === 'paused') {
      download.state = 'progressing';
      return true;
    }
    return false;
  }

  async cancelDownload(downloadId) {
    const download = this.downloads.get(downloadId);
    if (!download) return false;

    download.state = 'cancelled';
    download.endTime = Date.now();

    if (fs.existsSync(download.savePath)) {
      fs.unlinkSync(download.savePath);
    }

    return true;
  }

  async openDownload(downloadId) {
    const download = this.downloads.get(downloadId);
    if (!download || download.state !== 'completed') return false;

    try {
      await shell.openPath(download.savePath);
      return true;
    } catch {
      return false;
    }
  }

  clearDownloads() {
    for (const [id, download] of this.downloads) {
      if (download.state === 'completed' || download.state === 'cancelled') {
        this.downloads.delete(id);
      }
    }
    return true;
  }

  notifyStart(id, info) {
    this.sendToAllWindows('download-started', { id, ...info });
  }

  notifyProgress(id, info) {
    this.sendToAllWindows('download-progress', {
      id,
      progress: info.progress,
      receivedBytes: info.receivedBytes,
      totalBytes: info.totalBytes,
    });
  }

  notifyComplete(id, info) {
    this.sendToAllWindows('download-completed', {
      id,
      filename: info.filename,
      savePath: info.savePath,
    });
  }

  notifyError(id, info) {
    this.sendToAllWindows('download-error', {
      id,
      error: info.error,
    });
  }

  sendToAllWindows(channel, data) {
    const { BrowserWindow } = require('electron');
    const windows = BrowserWindow.getAllWindows();
    for (const win of windows) {
      win.webContents.send(channel, data);
    }
  }

  getSettings() {
    return this.settings;
  }
}

module.exports = DownloadManager;
