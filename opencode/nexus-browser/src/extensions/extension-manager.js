const fs = require('fs');
const path = require('path');
const { promisify } = require('util');
const { exec } = require('child_process');
const execAsync = promisify(exec);

const ChromeWebStoreBridge = require('./chrome-webstore-bridge');
const PermissionManager = require('./permission-manager');

class ExtensionManager {
  constructor(session, extensionsPath) {
    this.session = session;
    this.extensionsPath = extensionsPath;
    this.bridge = new ChromeWebStoreBridge();
    this.permissionManager = new PermissionManager();
    this.extensions = new Map();

    this.loadInstalledExtensions();
  }

  async loadInstalledExtensions() {
    if (!fs.existsSync(this.extensionsPath)) {
      return;
    }

    const entries = fs.readdirSync(this.extensionsPath);
    for (const entry of entries) {
      const extPath = path.join(this.extensionsPath, entry);
      if (fs.statSync(extPath).isDirectory()) {
        try {
          const manifestPath = path.join(extPath, 'manifest.json');
          if (fs.existsSync(manifestPath)) {
            const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
            this.extensions.set(entry, {
              id: entry,
              name: manifest.name || entry,
              version: manifest.version || '1.0.0',
              description: manifest.description || '',
              icon: manifest.icons ? manifest.icons['48'] || manifest.icons['128'] || null : null,
              enabled: true,
              path: extPath,
              manifest
            });
          }
        } catch (err) {
          console.error(`Failed to load extension ${entry}:`, err);
        }
      }
    }
  }

  async installFromWebStore(extensionId) {
    try {
      const extPath = await this.bridge.downloadExtension(extensionId, this.extensionsPath);
      if (extPath) {
        const manifestPath = path.join(extPath, 'manifest.json');
        const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));

        const permissionAnalysis = this.permissionManager.analyze(manifest.permissions || []);

        const extInfo = {
          id: extensionId,
          name: manifest.name || extensionId,
          version: manifest.version || '1.0.0',
          description: manifest.description || '',
          icon: manifest.icons ? manifest.icons['48'] || manifest.icons['128'] || null : null,
          enabled: true,
          path: extPath,
          manifest,
          permissions: permissionAnalysis
        };

        this.extensions.set(extensionId, extInfo);

        await this.session.loadExtension(extPath);

        return extInfo;
      }
      return null;
    } catch (err) {
      console.error('Failed to install extension:', err);
      return null;
    }
  }

  async loadUnpackedExtension(extensionPath) {
    try {
      const manifestPath = path.join(extensionPath, 'manifest.json');
      if (!fs.existsSync(manifestPath)) {
        throw new Error('Invalid extension: manifest.json not found');
      }

      const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
      const id = `unpacked_${Date.now()}`;

      const destPath = path.join(this.extensionsPath, id);
      fs.cpSync(extensionPath, destPath, { recursive: true });

      const extInfo = {
        id,
        name: manifest.name || id,
        version: manifest.version || '1.0.0',
        description: manifest.description || '',
        icon: manifest.icons ? manifest.icons['48'] || manifest.icons['128'] || null : null,
        enabled: true,
        path: destPath,
        manifest,
        unpacked: true
      };

      this.extensions.set(id, extInfo);
      await this.session.loadExtension(destPath);

      return extInfo;
    } catch (err) {
      console.error('Failed to load unpacked extension:', err);
      return null;
    }
  }

  async toggleExtension(extensionId, enabled) {
    const ext = this.extensions.get(extensionId);
    if (!ext) return false;

    ext.enabled = enabled;

    if (enabled) {
      await this.session.loadExtension(ext.path);
    } else {
      this.session.removeExtension(ext.path);
    }

    return true;
  }

  async uninstallExtension(extensionId) {
    const ext = this.extensions.get(extensionId);
    if (!ext) return false;

    this.session.removeExtension(ext.path);
    this.extensions.delete(extensionId);

    if (fs.existsSync(ext.path)) {
      fs.rmSync(ext.path, { recursive: true, force: true });
    }

    return true;
  }

  getExtensions() {
    return Array.from(this.extensions.values()).map(ext => ({
      id: ext.id,
      name: ext.name,
      version: ext.version,
      description: ext.description,
      icon: ext.icon,
      enabled: ext.enabled,
      unpacked: ext.unpacked || false,
      permissions: ext.permissions || null
    }));
  }

  analyzePermissions(permissions) {
    return this.permissionManager.analyze(permissions);
  }
}

module.exports = ExtensionManager;
