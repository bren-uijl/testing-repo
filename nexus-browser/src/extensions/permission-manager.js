const PERMISSIONS = {
  activeTab: {
    name: 'Active Tab',
    description: 'Access the currently active tab',
    risk: 'low',
  },
  tabs: {
    name: 'Tabs',
    description: 'Access your tabs and browsing activity',
    risk: 'medium',
  },
  storage: {
    name: 'Storage',
    description: 'Access extension storage',
    risk: 'low',
  },
  bookmarks: {
    name: 'Bookmarks',
    description: 'Read and modify your bookmarks',
    risk: 'medium',
  },
  history: {
    name: 'History',
    description: 'Access your browsing history',
    risk: 'high',
  },
  cookies: {
    name: 'Cookies',
    description: 'Access cookies for websites you visit',
    risk: 'high',
  },
  webRequest: {
    name: 'Web Request',
    description: 'Intercept and modify web requests',
    risk: 'high',
  },
  webNavigation: {
    name: 'Web Navigation',
    description: 'Track navigation events',
    risk: 'medium',
  },
  notifications: {
    name: 'Notifications',
    description: 'Show desktop notifications',
    risk: 'low',
  },
  contextMenus: {
    name: 'Context Menus',
    description: 'Add items to context menus',
    risk: 'low',
  },
  downloads: {
    name: 'Downloads',
    description: 'Manage downloads',
    risk: 'medium',
  },
  clipboardRead: {
    name: 'Clipboard Read',
    description: 'Read clipboard content',
    risk: 'medium',
  },
  clipboardWrite: {
    name: 'Clipboard Write',
    description: 'Write to clipboard',
    risk: 'low',
  },
  geolocation: {
    name: 'Geolocation',
    description: 'Access your location',
    risk: 'high',
  },
  microphone: {
    name: 'Microphone',
    description: 'Access your microphone',
    risk: 'high',
  },
  nativeMessaging: {
    name: 'Native Messaging',
    description: 'Communicate with native applications',
    risk: 'high',
  },
  proxy: {
    name: 'Proxy',
    description: 'Control proxy settings',
    risk: 'high',
  },
  management: {
    name: 'Management',
    description: 'Manage extensions and themes',
    risk: 'high',
  },
  privacy: {
    name: 'Privacy',
    description: 'Access privacy-related settings',
    risk: 'medium',
  },
  scripting: {
    name: 'Scripting',
    description: 'Inject scripts into web pages',
    risk: 'high',
  },
  declarativeNetRequest: {
    name: 'Declarative Net Request',
    description: 'Block or modify network requests',
    risk: 'high',
  },
  declarativeNetRequestFeedback: {
    name: 'Net Request Feedback',
    description: 'View statistics on blocked requests',
    risk: 'low',
  },
};

class PermissionManager {
  constructor() {
    this.grantedPermissions = new Map();
  }

  analyzePermissions(manifest) {
    const permissions = manifest.permissions || [];
    const hostPermissions = manifest.host_permissions || [];

    const analyzed = permissions.map(perm => ({
      permission: perm,
      ...PERMISSIONS[perm] || { name: perm, description: perm, risk: 'unknown' },
    }));

    const riskLevel = this.calculateRiskLevel(analyzed);

    return {
      permissions: analyzed,
      hostPermissions,
      riskLevel,
      hasHighRisk: analyzed.some(p => p.risk === 'high'),
    };
  }

  calculateRiskLevel(permissions) {
    const highRisk = permissions.filter(p => p.risk === 'high').length;
    const mediumRisk = permissions.filter(p => p.risk === 'medium').length;

    if (highRisk >= 3) return 'high';
    if (highRisk >= 1 || mediumRisk >= 3) return 'medium';
    return 'low';
  }

  shouldPromptForPermissions(analyzed) {
    return analyzed.hasHighRisk;
  }

  grantPermissions(extId, permissions) {
    this.grantedPermissions.set(extId, permissions);
  }

  revokePermissions(extId) {
    this.grantedPermissions.delete(extId);
  }

  hasPermission(extId, permission) {
    const perms = this.grantedPermissions.get(extId);
    return perms && perms.includes(permission);
  }

  getPermissionPromptHTML(analyzed, extensionName) {
    const riskColors = {
      low: '#4ecca3',
      medium: '#ffc857',
      high: '#e94560',
    };

    const riskColor = riskColors[analyzed.riskLevel] || '#a0a0a0';

    return `
      <div class="permission-prompt">
        <h3>Permissions for ${extensionName}</h3>
        <div class="risk-badge" style="background: ${riskColor}">
          Risk Level: ${analyzed.riskLevel.toUpperCase()}
        </div>
        <ul class="permission-list">
          ${analyzed.permissions.map(p => `
            <li class="permission-item risk-${p.risk}">
              <span class="perm-name">${p.name}</span>
              <span class="perm-desc">${p.description}</span>
              <span class="perm-risk risk-${p.risk}">${p.risk}</span>
            </li>
          `).join('')}
        </ul>
        ${analyzed.hostPermissions.length > 0 ? `
          <div class="host-permissions">
            <h4>Host Permissions</h4>
            <ul>
              ${analyzed.hostPermissions.map(h => `<li>${h}</li>`).join('')}
            </ul>
          </div>
        ` : ''}
        <div class="permission-actions">
          <button class="btn-deny">Deny</button>
          <button class="btn-allow">Allow</button>
        </div>
      </div>
    `;
  }
}

module.exports = PermissionManager;
