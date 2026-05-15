const fs = require('fs');
const path = require('path');

class PrivacyShield {
  constructor() {
    this.enabled = true;
    this.blockedCount = 0;
    this.settingsPath = path.join(require('electron').app.getPath('userData'), 'privacy-settings.json');

    this.trackerDomains = [
      'google-analytics.com',
      'analytics.google.com',
      'facebook.com/tr',
      'connect.facebook.net',
      'pixel.facebook.com',
      'doubleclick.net',
      'adservice.google.com',
      'googletagmanager.com',
      'googletagservices.com',
      'adsystem.com',
      'amazon-adsystem.com',
      'analytics.twitter.com',
      't.co',
      'bat.bing.com',
      'ads.bing.com',
      'scorecardresearch.com',
      'quantserve.com',
      'exelator.com',
      '2mdn.net',
      'invitemedia.com',
      'adnxs.com',
      'rubiconproject.com',
      'openx.net',
      'pubmatic.com',
      'criteo.com',
      'taboola.com',
      'outbrain.com',
      'media.net',
      'ads.yahoo.com',
      'analytics.yahoo.com'
    ];

    this.adDomains = [
      'adservice.google.com',
      'pagead2.googlesyndication.com',
      'tpc.googlesyndication.com',
      'googleads.g.doubleclick.net',
      'adservice.google.com',
      'ads.yahoo.com',
      'adserver.yahoo.com',
      'adspecs.yahoo.com',
      'advertising.com',
      'adsrvr.org',
      'adsymptotic.com',
      'adnxs.com',
      'adnxs.net',
      'rubiconproject.com',
      'openx.net',
      'pubmatic.com',
      'criteo.com',
      'criteo.net',
      'taboola.com',
      'outbrain.com'
    ];

    this.customBlocklist = [];
    this.whitelist = [];

    this.loadSettings();
  }

  loadSettings() {
    try {
      if (fs.existsSync(this.settingsPath)) {
        const settings = JSON.parse(fs.readFileSync(this.settingsPath, 'utf8'));
        this.enabled = settings.enabled !== undefined ? settings.enabled : true;
        this.blockedCount = settings.blockedCount || 0;
        this.customBlocklist = settings.customBlocklist || [];
        this.whitelist = settings.whitelist || [];
      }
    } catch (err) {
      console.error('Failed to load privacy settings:', err);
    }
  }

  saveSettings(additionalSettings = {}) {
    const settings = {
      enabled: this.enabled,
      blockedCount: this.blockedCount,
      customBlocklist: this.customBlocklist,
      whitelist: this.whitelist,
      ...additionalSettings
    };

    try {
      fs.writeFileSync(this.settingsPath, JSON.stringify(settings, null, 2));
    } catch (err) {
      console.error('Failed to save privacy settings:', err);
    }
  }

  getBlockedDomains() {
    return [...new Set([...this.trackerDomains, ...this.adDomains, ...this.customBlocklist])];
  }

  addBlockedDomain(domain) {
    if (!this.customBlocklist.includes(domain)) {
      this.customBlocklist.push(domain);
      this.saveSettings();
    }
    return this.getBlockedDomains();
  }

  removeBlockedDomain(domain) {
    this.customBlocklist = this.customBlocklist.filter(d => d !== domain);
    this.saveSettings();
    return this.getBlockedDomains();
  }

  addToWhitelist(domain) {
    if (!this.whitelist.includes(domain)) {
      this.whitelist.push(domain);
      this.saveSettings();
    }
  }

  removeFromWhitelist(domain) {
    this.whitelist = this.whitelist.filter(d => d !== domain);
    this.saveSettings();
  }

  isWhitelisted(domain) {
    return this.whitelist.some(w => domain.includes(w));
  }

  incrementBlockCount() {
    this.blockedCount++;
    this.saveSettings();
  }

  getStats() {
    return {
      enabled: this.enabled,
      blockedCount: this.blockedCount,
      trackerCount: this.trackerDomains.length,
      adCount: this.adDomains.length,
      customBlocklistCount: this.customBlocklist.length,
      whitelistCount: this.whitelist.length
    };
  }

  isEnabled() {
    return this.enabled;
  }

  setEnabled(enabled) {
    this.enabled = enabled;
    this.saveSettings();
  }

  getSettings() {
    return {
      enabled: this.enabled,
      blockTrackers: true,
      blockAds: true,
      customBlocklist: this.customBlocklist,
      whitelist: this.whitelist
    };
  }

  saveSettings(settings) {
    if (settings.blockTrackers !== undefined) {
      if (!settings.blockTrackers) {
        this.trackerDomains.length = 0;
      }
    }
    if (settings.blockAds !== undefined) {
      if (!settings.blockAds) {
        this.adDomains.length = 0;
      }
    }
    this.saveSettings(settings);
  }
}

module.exports = PrivacyShield;
