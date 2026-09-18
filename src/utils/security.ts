/**
 * Security & Anti-Inspection Utility for AuraTrack
 * Prevents inspection, keyboard shortcuts, right-click context menu,
 * and actively traps/neutralizes DevTools when opened via browser menus or shortcuts.
 */

export function initSecurity(): void {
  // Only execute in browser environment
  if (typeof window === 'undefined') return;

  // 1. Disable Right-Click Context Menu
  document.addEventListener(
    'contextmenu',
    (e: MouseEvent) => {
      e.preventDefault();
      e.stopPropagation();
      return false;
    },
    { capture: true }
  );

  // 2. Block Inspect & DevTools Shortcut Combinations
  const blockedKeyCodes = new Set(['F12']);
  
  document.addEventListener(
    'keydown',
    (e: KeyboardEvent) => {
      const isCtrlOrCmd = e.ctrlKey || e.metaKey;
      const isShift = e.shiftKey;
      const key = e.key ? e.key.toUpperCase() : '';
      const code = e.code;

      // F12 or Shift+F10
      if (e.key === 'F12' || code === 'F12' || blockedKeyCodes.has(e.key) || (isShift && (e.key === 'F10' || code === 'F10'))) {
        e.preventDefault();
        e.stopPropagation();
        return false;
      }

      // Ctrl+Shift+I (Inspect), Ctrl+Shift+J (Console), Ctrl+Shift+C (Inspect Element), Ctrl+Shift+K (Firefox)
      if (isCtrlOrCmd && isShift && (key === 'I' || key === 'J' || key === 'C' || key === 'K' || key === 'E')) {
        e.preventDefault();
        e.stopPropagation();
        return false;
      }

      // Ctrl+U (View Source), Ctrl+S (Save Page), Ctrl+P (Print)
      if (isCtrlOrCmd && (key === 'U' || key === 'S' || key === 'P')) {
        e.preventDefault();
        e.stopPropagation();
        return false;
      }

      // Cmd+Option+I / Cmd+Option+J / Cmd+Option+C on macOS
      if (e.metaKey && e.altKey && (key === 'I' || key === 'J' || key === 'C')) {
        e.preventDefault();
        e.stopPropagation();
        return false;
      }
    },
    { capture: true }
  );

  // 3. Disable text selection dragging of sensitive UI if triggered
  document.addEventListener('dragstart', (e: DragEvent) => {
    e.preventDefault();
  });

  // 4. Overwrite Console Methods in Production to prevent inspection leakage
  const noop = () => {};
  const methods: (keyof Console)[] = [
    'log',
    'debug',
    'info',
    'warn',
    'error',
    'table',
    'trace',
    'dir',
    'dirxml',
    'group',
    'groupCollapsed',
    'groupEnd',
    'time',
    'timeEnd',
    'profile',
    'profileEnd'
  ];

  try {
    methods.forEach((m) => {
      if (window.console && window.console[m]) {
        // @ts-expect-error override
        window.console[m] = noop;
      }
    });
  } catch {}

  // Keep console wiped
  setInterval(() => {
    try {
      if (window.console && window.console.clear) {
        window.console.clear();
      }
    } catch {}
  }, 1000);

  // 5. Active Anti-Debugging Trap
  // If DevTools is opened from browser settings or menu, this halts execution in a debugger loop
  const antiDebugLoop = () => {
    function debugTrap(counter: number) {
      if (('' + counter / counter).length !== 1 || counter === 0) {
        (function () {}.constructor('debugger')());
      } else {
        (function () {}.constructor('debugger')());
      }
      debugTrap(++counter);
    }
    try {
      debugTrap(0);
    } catch {
      setTimeout(antiDebugLoop, 100);
    }
  };

  // Run in a worker / interval to constantly block inspection if devtools opens
  setInterval(() => {
    const startTime = performance.now();
    (function () {}.constructor('debugger')());
    const endTime = performance.now();
    // If debugger stopped execution, time taken will be noticeable (> 100ms)
    if (endTime - startTime > 100) {
      showDevToolsBlockScreen();
    }
  }, 500);

  // 6. DevTools Dimension & Getter Detection (Detects docked & detached devtools)
  const elementDetector = new Image();
  let devtoolsOpen = false;

  Object.defineProperty(elementDetector, 'id', {
    get: function () {
      devtoolsOpen = true;
      showDevToolsBlockScreen();
      return 'detector';
    },
  });

  const checkDevTools = () => {
    const threshold = 160;
    const widthDiff = window.outerWidth - window.innerWidth > threshold;
    const heightDiff = window.outerHeight - window.innerHeight > threshold;

    if (widthDiff || heightDiff) {
      devtoolsOpen = true;
      showDevToolsBlockScreen();
    }

    // Trigger getter when console evaluates
    try {
      // @ts-expect-error detector
      console.log(elementDetector);
    } catch {}
  };

  window.addEventListener('resize', checkDevTools);
  setInterval(checkDevTools, 1000);
}

function showDevToolsBlockScreen(): void {
  let blockOverlay = document.getElementById('auratrack-security-overlay');
  if (!blockOverlay) {
    blockOverlay = document.createElement('div');
    blockOverlay.id = 'auratrack-security-overlay';
    blockOverlay.style.position = 'fixed';
    blockOverlay.style.top = '0';
    blockOverlay.style.left = '0';
    blockOverlay.style.width = '100vw';
    blockOverlay.style.height = '100vh';
    blockOverlay.style.backgroundColor = '#030712';
    blockOverlay.style.color = '#f87171';
    blockOverlay.style.display = 'flex';
    blockOverlay.style.flexDirection = 'column';
    blockOverlay.style.alignItems = 'center';
    blockOverlay.style.justifyContent = 'center';
    blockOverlay.style.zIndex = '2147483647';
    blockOverlay.style.fontFamily = 'system-ui, -apple-system, sans-serif';
    blockOverlay.style.textAlign = 'center';
    blockOverlay.style.padding = '20px';

    blockOverlay.innerHTML = `
      <div style="max-width: 480px; background: rgba(15, 23, 42, 0.9); border: 1px solid rgba(239, 68, 68, 0.3); border-radius: 16px; padding: 32px; box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.7);">
        <div style="font-size: 48px; margin-bottom: 16px;">🛡️</div>
        <h2 style="font-size: 22px; font-weight: 700; color: #ffffff; margin-bottom: 8px;">Security Notice</h2>
        <p style="font-size: 14px; color: #94a3b8; line-height: 1.6; margin-bottom: 24px;">
          Developer tools and page inspection are restricted on AuraTrack for enterprise data protection and security.
        </p>
        <button onclick="window.location.reload()" style="background: #6366f1; color: white; border: none; border-radius: 8px; padding: 10px 20px; font-size: 14px; font-weight: 600; cursor: pointer; transition: background 0.2s;">
          Reload Page
        </button>
      </div>
    `;
    document.body.appendChild(blockOverlay);
  }
}
