const https = require('https');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');
const crypto = require('crypto');
const { execSync } = require('child_process');

class ChromeWebStoreBridge {
  constructor() {
    this.apiUrl = 'https://clients2.google.com/service/update2/crx';
    this.webStoreUrl = 'https://chrome.google.com/webstore/detail';
  }

  async downloadExtension(extensionId, destinationPath) {
    try {
      const crxPath = path.join(destinationPath, `${extensionId}.crx`);
      const extractPath = path.join(destinationPath, extensionId);

      const crxUrl = `${this.apiUrl}?response=redirect&prodversion=120.0.0.0&acceptformat=crx2,crx3&x=id%3D${extensionId}%26installsource%3Dondemand%26uc`;

      await this.downloadFile(crxUrl, crxPath);

      await this.extractCrx(crxPath, extractPath);

      fs.unlinkSync(crxPath);

      const manifestPath = path.join(extractPath, 'manifest.json');
      if (!fs.existsSync(manifestPath)) {
        throw new Error('Extension manifest not found after extraction');
      }

      return extractPath;
    } catch (err) {
      console.error('Failed to download extension:', err);
      return null;
    }
  }

  downloadFile(url, outputPath) {
    return new Promise((resolve, reject) => {
      const protocol = url.startsWith('https') ? https : http;

      const file = fs.createWriteStream(outputPath);

      protocol.get(url, { followRedirects: true }, (response) => {
        if (response.statusCode === 301 || response.statusCode === 302) {
          this.downloadFile(response.headers.location, outputPath).then(resolve).catch(reject);
          return;
        }

        if (response.statusCode !== 200) {
          reject(new Error(`Failed to download: ${response.statusCode}`));
          return;
        }

        response.pipe(file);

        file.on('finish', () => {
          file.close();
          resolve();
        });
      }).on('error', reject);
    });
  }

  async extractCrx(crxPath, extractPath) {
    fs.mkdirSync(extractPath, { recursive: true });

    const crxBuffer = fs.readFileSync(crxPath);

    let zipStart = 0;

    if (crxBuffer[0] === 0x43 && crxBuffer[1] === 0x72 && crxBuffer[2] === 0x32 && crxBuffer[3] === 0x34) {
      const headerVersion = crxBuffer.readUInt32LE(4);
      const pubKeyLength = crxBuffer.readUInt32LE(8);
      const sigLength = crxBuffer.readUInt32LE(12);

      if (headerVersion === 2) {
        zipStart = 16 + pubKeyLength + sigLength;
      } else if (headerVersion === 3) {
        const pubKey2Length = crxBuffer.readUInt32LE(16);
        zipStart = 20 + pubKeyLength + sigLength + pubKey2Length;
      }
    } else if (crxBuffer[0] === 0x50 && crxBuffer[1] === 0x4b) {
      zipStart = 0;
    }

    const zipBuffer = crxBuffer.slice(zipStart);

    const tempZipPath = path.join(extractPath, '_temp.zip');
    fs.writeFileSync(tempZipPath, zipBuffer);

    try {
      if (process.platform === 'win32') {
        const { execSync } = require('child_process');
        execSync(`powershell -command "Expand-Archive -Path '${tempZipPath}' -DestinationPath '${extractPath}' -Force"`);
      } else {
        execSync(`unzip -o "${tempZipPath}" -d "${extractPath}"`);
      }
    } catch (err) {
      const AdmZip = require('adm-zip');
      const zip = new AdmZip(tempZipPath);
      zip.extractAllTo(extractPath, true);
    }

    fs.unlinkSync(tempZipPath);
  }

  async getExtensionInfo(extensionId) {
    return new Promise((resolve, reject) => {
      const url = `https://chrome.google.com/webstore/detail/${extensionId}`;

      https.get(url, (res) => {
        let data = '';
        res.on('data', chunk => data += chunk);
        res.on('end', () => {
          try {
            const nameMatch = data.match(/<meta name="description" content="([^"]+)"/);
            resolve({
              id: extensionId,
              name: nameMatch ? nameMatch[1] : 'Unknown Extension',
              url: `https://chrome.google.com/webstore/detail/${extensionId}`
            });
          } catch {
            resolve({ id: extensionId, name: 'Unknown Extension', url });
          }
        });
      }).on('error', reject);
    });
  }
}

module.exports = ChromeWebStoreBridge;
