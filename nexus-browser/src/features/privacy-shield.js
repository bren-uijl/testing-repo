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
];

const AD_DOMAINS = [
  'googlesyndication.com',
  'googleadservices.com',
  'ads.google.com',
  'adwords.google.com',
  'ad.doubleclick.net',
  'adserver.com',
  'adservice.google.com',
  'pagead2.googlesyndication.com',
  'tpc.googlesyndication.com',
  'adsystem.amazon.com',
  'amazon-adsystem.com',
  'ads.yahoo.com',
  'advertising.com',
  'adsrvr.org',
  'bidswitch.net',
  'casalemedia.com',
  'indexww.com',
];

class PrivacyShield {
  constructor() {
    this.enabled = true;
    this.blockedRequests = 0;
    this.blockedTrackers = 0;
    this.blockedAds = 0;
    this.customBlocklist = [];
    this.whitelist = [];

    this.setupRequestBlocking();
  }

  setupRequestBlocking() {
    session.defaultSession.webRequest.onBeforeRequest((details, callback) => {
      if (!this.enabled) {
        callback({ cancel: false });
        return;
      }

      const url = new URL(details.url);
      const hostname = url.hostname;

      if (this.isWhitelisted(hostname)) {
        callback({ cancel: false });
        return;
      }

      if (this.shouldBlock(hostname)) {
        this.blockedRequests++;

        if (this.isTracker(hostname)) {
          this.blockedTrackers++;
        }

        if (this.isAd(hostname)) {
          this.blockedAds++;
        }

        callback({ cancel: true });
      } else {
        callback({ cancel: false });
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

  toggle() {
    this.enabled = !this.enabled;
    return this.enabled;
  }

  addToBlocklist(domain) {
    if (!this.customBlocklist.includes(domain)) {
      this.customBlocklist.push(domain);
    }
  }

  removeFromBlocklist(domain) {
    this.customBlocklist = this.customBlocklist.filter(d => d !== domain);
  }

  addToWhitelist(domain) {
    if (!this.whitelist.includes(domain)) {
      this.whitelist.push(domain);
    }
  }

  removeFromWhitelist(domain) {
    this.whitelist = this.whitelist.filter(d => d !== domain);
  }

  getStats() {
    return {
      enabled: this.enabled,
      blockedRequests: this.blockedRequests,
      blockedTrackers: this.blockedTrackers,
      blockedAds: this.blockedAds,
      customBlocklist: this.customBlocklist,
      whitelist: this.whitelist,
    };
  }

  resetStats() {
    this.blockedRequests = 0;
    this.blockedTrackers = 0;
    this.blockedAds = 0;
  }
}

module.exports = PrivacyShield;
