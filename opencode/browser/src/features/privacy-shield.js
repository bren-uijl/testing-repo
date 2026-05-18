const fs = require('fs');
const path = require('path');
const { session } = require('electron');

const TRACKER_DOMAINS = [
  'google-analytics.com',
  'doubleclick.net',
  'facebook.com/tr',
  'facebook.net',
  'fbcdn.net',
  'analytics.google.com',
  'tagmanager.google.com',
  'adservice.google.com',
  'adsystem.com',
  'adservice.com',
  'adnxs.com',
  'rubiconproject.com',
  'pubmatic.com',
  'criteo.com',
  'adsrvr.org',
  'mathtag.com',
  'quantserve.com',
  'scorecardresearch.com',
  'comscore.com',
  'nielsen.com',
  'hotjar.com',
  'mouseflow.com',
  'fullstory.com',
  'mixpanel.com',
  'amplitude.com',
  'segment.com',
  'optimizely.com',
  'vwo.com',
  'crazyegg.com',
  'clicktale.com',
  'connect.facebook.net',
  'pixel.facebook.com',
  'googletagmanager.com',
  'googletagservices.com',
  'analytics.twitter.com',
  't.co',
  'bat.bing.com',
  'ads.bing.com',
  'exelator.com',
  '2mdn.net',
  'invitemedia.com',
  'openx.net',
  'taboola.com',
  'outbrain.com',
  'media.net',
  'analytics.yahoo.com',
];

const AD_DOMAINS = [
  'googlesyndication.com',
  'googleadservices.com',
  'ads.google.com',
  'adwords.google.com',
  'ad.doubleclick.net',
  'adserver.com',
  'pagead2.googlesyndication.com',
  'tpc.googlesyndication.com',
  'adsystem.amazon.com',
  'amazon-adsystem.com',
  'ads.yahoo.com',
  'advertising.com',
  'bidswitch.net',
  'casalemedia.com',
  'indexww.com',
  'googleads.g.doubleclick.net',
  'adserver.yahoo.com',
  'adspecs.yahoo.com',
  'adsymptotic.com',
  'adnxs.net',
  'criteo.net',
];

class PrivacyShield {
  constructor() {
    this.enabled = true;
    this.blockedRequests = 0;
    this.blockedTrackers = 0;
    this.blockedAds = 0;
    this.blockedCount = 0;
    this.customBlocklist = [];
    this.whitelist = [];
    this.settingsPath = path.join(require('electron').app.getPath('userData'), 'privacy-settings.json');

    this.loadSettings();
    this.setupRequestBlocking();
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
      ...additionalSettings,
    };

    try {
      fs.writeFileSync(this.settingsPath, JSON.stringify(settings, null, 2));
    } catch (err) {
      console.error('Failed to save privacy settings:', err);
    }
  }

  setupRequestBlocking() {
    session.defaultSession.webRequest.onBeforeRequest((details, callback) => {
      if (!this.enabled) {
        callback({});
        return;
      }

      const url = new URL(details.url);
      const hostname = url.hostname;

      if (this.isWhitelisted(hostname)) {
        callback({});
        return;
      }

      if (this.shouldBlock(hostname)) {
        this.blockedRequests++;
        this.blockedCount++;

        if (this.isTracker(hostname)) {
          this.blockedTrackers++;
        }

        if (this.isAd(hostname)) {
          this.blockedAds++;
        }

        callback({ cancel: true });
      } else {
        callback({});
      }
    });

    session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
      const responseHeaders = { ...details.responseHeaders };

      delete responseHeaders['x-frame-options'];
      delete responseHeaders['X-Frame-Options'];

      if (responseHeaders['set-cookie']) {
        responseHeaders['set-cookie'] = responseHeaders['set-cookie'].map(cookie => {
          return cookie.replace(/;\s*Secure/gi, '').replace(/;\s*SameSite=None/gi, '; SameSite=Lax');
        });
      }

      callback({ responseHeaders });
    });

    session.defaultSession.webRequest.onBeforeSendHeaders((details, callback) => {
      const headers = { ...details.requestHeaders };
      const trackingHeaders = ['X-Do-Not-Track', 'DNT', 'Sec-GPC'];
      trackingHeaders.forEach(header => {
        if (headers[header]) {
          delete headers[header];
        }
      });
      callback({ requestHeaders: headers });
    });
  }

  shouldBlock(hostname) {
    return (
      TRACKER_DOMAINS.some(domain => hostname.endsWith(domain)) ||
      AD_DOMAINS.some(domain => hostname.endsWith(domain)) ||
      this.customBlocklist.some(domain => hostname.endsWith(domain))
    );
  }

  isTracker(hostname) {
    return TRACKER_DOMAINS.some(domain => hostname.endsWith(domain));
  }

  isAd(hostname) {
    return AD_DOMAINS.some(domain => hostname.endsWith(domain));
  }

  isWhitelisted(hostname) {
    return this.whitelist.some(domain => hostname.endsWith(domain));
  }

  getBlockedDomains() {
    return [...new Set([...TRACKER_DOMAINS, ...AD_DOMAINS, ...this.customBlocklist])];
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

  toggle() {
    this.enabled = !this.enabled;
    this.saveSettings();
    return this.enabled;
  }

  isEnabled() {
    return this.enabled;
  }

  setEnabled(enabled) {
    this.enabled = enabled;
    this.saveSettings();
  }

  incrementBlockCount() {
    this.blockedCount++;
    this.saveSettings();
  }

  getStats() {
    return {
      enabled: this.enabled,
      blockedRequests: this.blockedRequests,
      blockedTrackers: this.blockedTrackers,
      blockedAds: this.blockedAds,
      blockedCount: this.blockedCount,
      trackerCount: TRACKER_DOMAINS.length,
      adCount: AD_DOMAINS.length,
      customBlocklistCount: this.customBlocklist.length,
      whitelistCount: this.whitelist.length,
      customBlocklist: this.customBlocklist,
      whitelist: this.whitelist,
    };
  }

  resetStats() {
    this.blockedRequests = 0;
    this.blockedTrackers = 0;
    this.blockedAds = 0;
    this.blockedCount = 0;
    this.saveSettings();
  }

  getSettings() {
    return {
      enabled: this.enabled,
      blockTrackers: true,
      blockAds: true,
      customBlocklist: this.customBlocklist,
      whitelist: this.whitelist,
    };
  }
}

module.exports = PrivacyShield;
