class PermissionManager {
  constructor() {
    this.permissionRisks = {
      high: [
        'webRequest',
        'webRequestBlocking',
        'webNavigation',
        'declarativeNetRequest',
        'declarativeNetRequestWithHostAccess',
        'declarativeNetRequestFeedback',
        'proxy',
        'debugger',
        'system.cpu',
        'system.memory',
        'system.display',
        'system.storage'
      ],
      medium: [
        'tabs',
        'bookmarks',
        'history',
        'downloads',
        'downloads.open',
        'management',
        'privacy',
        'sessions',
        'storage',
        'unlimitedStorage',
        'notifications',
        'geolocation',
        'clipboardRead',
        'clipboardWrite',
        'nativeMessaging'
      ],
      low: [
        'activeTab',
        'alarms',
        'background',
        'contextMenus',
        'contentSettings',
        'cookies',
        'declarativeContent',
        'fontSettings',
        'pageCapture',
        'scripting',
        'tabCapture',
        'topSites',
        'tts',
        'ttsEngine'
      ]
    };

    this.permissionDescriptions = {
      'webRequest': 'Can intercept and modify web requests',
      'webRequestBlocking': 'Can block web requests',
      'webNavigation': 'Can monitor navigation events',
      'declarativeNetRequest': 'Can modify network requests',
      'declarativeNetRequestWithHostAccess': 'Can modify network requests on specific hosts',
      'declarativeNetRequestFeedback': 'Can receive feedback about blocked requests',
      'proxy': 'Can control proxy settings',
      'debugger': 'Can attach debugger to tabs',
      'tabs': 'Can access tab information',
      'bookmarks': 'Can read and modify bookmarks',
      'history': 'Can access browsing history',
      'downloads': 'Can manage downloads',
      'downloads.open': 'Can open downloaded files',
      'management': 'Can manage other extensions',
      'privacy': 'Can modify browser privacy settings',
      'sessions': 'Can access recently closed tabs',
      'storage': 'Can access extension storage',
      'unlimitedStorage': 'Can use unlimited storage',
      'notifications': 'Can show notifications',
      'geolocation': 'Can access your location',
      'clipboardRead': 'Can read clipboard content',
      'clipboardWrite': 'Can write to clipboard',
      'nativeMessaging': 'Can communicate with native applications',
      'activeTab': 'Can access the active tab when you click the extension',
      'alarms': 'Can schedule alarms',
      'contextMenus': 'Can add items to context menus',
      'cookies': 'Can access and modify cookies',
      'scripting': 'Can inject scripts into web pages',
      'tabCapture': 'Can capture tab content'
    };
  }

  analyze(permissions) {
    const analysis = {
      high: [],
      medium: [],
      low: [],
      unknown: [],
      riskLevel: 'low',
      summary: ''
    };

    permissions.forEach(perm => {
      let permName = perm;

      if (typeof perm === 'object') {
        permName = perm.permission || JSON.stringify(perm);
      }

      if (this.permissionRisks.high.includes(permName)) {
        analysis.high.push({
          name: permName,
          description: this.permissionDescriptions[permName] || 'High-risk permission'
        });
      } else if (this.permissionRisks.medium.includes(permName)) {
        analysis.medium.push({
          name: permName,
          description: this.permissionDescriptions[permName] || 'Medium-risk permission'
        });
      } else if (this.permissionRisks.low.includes(permName)) {
        analysis.low.push({
          name: permName,
          description: this.permissionDescriptions[permName] || 'Low-risk permission'
        });
      } else if (permName.startsWith('http://') || permName.startsWith('https://') || permName === '<all_urls>') {
        analysis.medium.push({
          name: permName,
          description: `Access to websites matching: ${permName}`
        });
      } else {
        analysis.unknown.push({
          name: permName,
          description: 'Unknown permission'
        });
      }
    });

    if (analysis.high.length > 0) {
      analysis.riskLevel = 'high';
      analysis.summary = `This extension requests ${analysis.high.length} high-risk permission(s). Review carefully before installing.`;
    } else if (analysis.medium.length > 2) {
      analysis.riskLevel = 'medium';
      analysis.summary = `This extension requests ${analysis.medium.length} permissions that could affect your privacy.`;
    } else {
      analysis.riskLevel = 'low';
      analysis.summary = 'This extension requests minimal permissions.';
    }

    return analysis;
  }

  getRiskColor(riskLevel) {
    switch (riskLevel) {
      case 'high': return '#e94560';
      case 'medium': return '#f9a825';
      case 'low': return '#4ecca3';
      default: return '#a0a0a0';
    }
  }

  getRiskIcon(riskLevel) {
    switch (riskLevel) {
      case 'high': return '⚠️';
      case 'medium': return '⚡';
      case 'low': return '✓';
      default: return '?';
    }
  }
}

module.exports = PermissionManager;
