const fs = require('fs');
const path = require('path');
const { app, session } = require('electron');
const crypto = require('crypto');

const CHROME_WEBSTORE_API = 'https://clients2.google.com/service/update2/crx';
const CHROME_WEBSTORE_URL = 'https://chrome.google.com/webstore';

class ExtensionManager {
  constructor() {
    this.extensionsDir = path.join(app.getPath('userData'), 'extensions');
    this.extensions = new Map();
    this.registry = new Map();

    this.ensureExtensionsDir();
    this.loadInstalledExtensions();
  }

  ensureExtensionsDir() {
    if (!fs.existsSync(this.extensionsDir)) {
      fs.mkdirSync(this.extensionsDir, { recursive: true });
    }
  }

  async loadInstalledExtensions() {
    try {
      const entries = fs.readdirSync(this.extensionsDir);

      for (const entry of entries) {
        const extPath = path.join(this.extensionsDir, entry);
        const manifestPath = path.join(extPath, 'manifest.json');

        if (fs.existsSync(manifestPath)) {
          try {
            const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
            this.extensions.set(manifest.name || entry, {
              id: entry,
              path: extPath,
              manifest,
              enabled: true,
            });
          } catch (error) {
            console.error(`Failed to load extension ${entry}:`, error);
          }
        }
      }
    } catch (error) {
      console.error('Failed to load extensions:', error);
    }
  }

  async installFromWebStore(extensionId) {
    try {
      const crxPath = await this.downloadCrx(extensionId);
      return await this.installFromCrx(crxPath);
    } catch (error) {
      console.error(`Failed to install extension ${extensionId}:`, error);
      throw error;
    }
  }

  async downloadCrx(extensionId) {
    const url = `${CHROME_WEBSTORE_API}?response=redirect&prodversion=${process.platform}&x=id%3D${extensionId}%26installsource%3Dondemand%26uc`;

    const response = await fetch(url, {
      redirect: 'follow',
    });

    if (!response.ok) {
      throw new Error(`Failed to download extension: ${response.statusText}`);
    }

    const buffer = Buffer.from(await response.arrayBuffer());
    const crxPath = path.join(this.extensionsDir, `${extensionId}.crx`);

    fs.writeFileSync(crxPath, buffer);
    return crxPath;
  }

  async installFromCrx(crxPath) {
    const extractPath = await this.extractCrx(crxPath);
    const manifest = await this.readManifest(extractPath);

    const extId = manifest.key
      ? this.generateExtensionId(manifest.key)
      : path.basename(extractPath);

    const destPath = path.join(this.extensionsDir, extId);

    if (fs.existsSync(destPath)) {
      fs.rmSync(destPath, { recursive: true });
    }

    fs.cpSync(extractPath, destPath, { recursive: true });

    const extensionInfo = {
      id: extId,
      path: destPath,
      manifest,
      enabled: true,
      installedAt: Date.now(),
    };

    this.extensions.set(extId, extensionInfo);

    try {
      await session.defaultSession.loadExtension(destPath);
    } catch (error) {
      console.error('Failed to load extension in session:', error);
    }

    return extensionInfo;
  }

  async extractCrx(crxPath) {
    const buffer = fs.readFileSync(crxPath);
    const extractDir = path.join(this.extensionsDir, 'temp', path.basename(crxPath, '.crx'));

    fs.mkdirSync(extractDir, { recursive: true });

    let zipStart = 0;

    if (buffer.slice(0, 4).toString() === 'Cr24') {
      const version = buffer.readUInt32LE(4);

      if (version === 2) {
        const pubKeyLength = buffer.readUInt32LE(8);
        const sigLength = buffer.readUInt32LE(12);
        zipStart = 16 + pubKeyLength + sigLength;
      } else if (version === 3) {
        const headerLength = buffer.readUInt32LE(8);
        zipStart = 12 + headerLength;
      }
    }

    const zipBuffer = buffer.slice(zipStart);
    const zipPath = path.join(extractDir, 'extension.zip');
    fs.writeFileSync(zipPath, zipBuffer);

    await this.unzip(zipPath, extractDir);

    fs.unlinkSync(zipPath);

    return extractDir;
  }

  async unzip(zipPath, destDir) {
    const AdmZip = require('adm-zip');
    const zip = new AdmZip(zipPath);
    zip.extractAllTo(destDir, true);
  }

  async readManifest(extPath) {
    const manifestPath = path.join(extPath, 'manifest.json');
    const content = fs.readFileSync(manifestPath, 'utf8');
    return JSON.parse(content);
  }

  generateExtensionId(publicKey) {
    const hash = crypto.createHash('sha256').update(publicKey).digest('hex');
    let id = '';

    for (let i = 0; i < 32; i++) {
      const charCode = parseInt(hash[i], 16);
      id += String.fromCharCode(97 + charCode);
    }

    return id.substring(0, 32);
  }

  async uninstallExtension(extId) {
    const ext = this.extensions.get(extId);
    if (!ext) return false;

    try {
      await session.defaultSession.removeExtension(extId);
    } catch (error) {
      console.error('Failed to remove extension from session:', error);
    }

    fs.rmSync(ext.path, { recursive: true, force: true });
    this.extensions.delete(extId);

    return true;
  }

  async enableExtension(extId) {
    const ext = this.extensions.get(extId);
    if (!ext) return false;

    ext.enabled = true;

    try {
      await session.defaultSession.loadExtension(ext.path);
    } catch (error) {
      console.error('Failed to enable extension:', error);
      return false;
    }

    return true;
  }

  async disableExtension(extId) {
    const ext = this.extensions.get(extId);
    if (!ext) return false;

    ext.enabled = false;

    try {
      await session.defaultSession.removeExtension(extId);
    } catch (error) {
      console.error('Failed to disable extension:', error);
    }

    return true;
  }

  getInstalledExtensions() {
    return Array.from(this.extensions.values()).map(ext => ({
      id: ext.id,
      name: ext.manifest.name || ext.id,
      version: ext.manifest.version || 'unknown',
      description: ext.manifest.description || '',
      path: ext.path,
      enabled: ext.enabled,
      manifest: ext.manifest,
    }));
  }

  searchWebStore(query) {
    const searchUrl = `${CHROME_WEBSTORE_URL}/category/extensions?q=${encodeURIComponent(query)}`;
    return searchUrl;
  }

  getExtensionUrl(extId) {
    return `${CHROME_WEBSTORE_URL}/detail/${extId}`;
  }
}

module.exports = ExtensionManager;
