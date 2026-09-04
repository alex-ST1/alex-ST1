// Main App Controller, UI Rendering & Event Orchestration
let currentTab = 'dashboard';
let savingsChart = null;
let donutViz = null;

document.addEventListener('DOMContentLoaded', () => {
  initApp();
});

function initApp() {
  renderNavigation();
  renderCurrentView();
  setupModalSheet();
  setupStoreSubscription();
  setupDesktopControls();

  // Initialize service worker if supported
  if ('serviceWorker' in navigator) {
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('./sw.js').catch(err => {
        console.log('SW registration note:', err);
      });
    });
  }
}

// Subscribe to store updates for rapid animations
function setupStoreSubscription() {
  store.subscribe((event, payload) => {
    if (event === 'DEPOSIT_ADDED') {
      handleRapidDepositRefresh(payload);
    } else if (event === 'DATA_RESET' || event === 'SETTINGS_UPDATED') {
      renderCurrentView();
    }
  });
}

// Rapid Reactive Refresh Animation on Deposit
function handleRapidDepositRefresh(data) {
  const { amount, oldTotal, newTotal, oldMonthSaved, newMonthSaved, bucketId, bucket } = data;
  const currency = store.state.settings.currency;

  // 1. Audio & Tactile Haptics
  if (store.state.settings.soundEnabled) {
    animEngine.playCashChime();
  }
  if (store.state.settings.hapticEnabled) {
    animEngine.haptic([15, 30, 20]);
  }

  // 2. Rolling Number Counter for Hero Total Savings
  const heroTotalEl = document.getElementById('heroTotalSavings');
  if (heroTotalEl) {
    animEngine.animateNumber(heroTotalEl, oldTotal, newTotal, 850, currency);
  }

  // 3. Rolling Number Counter for Current Month Savings
  const heroMonthEl = document.getElementById('heroMonthSavings');
  if (heroMonthEl) {
    animEngine.animateNumber(heroMonthEl, oldMonthSaved, newMonthSaved, 850, currency);
  }

  // 4. Flash Hero Card with radiant emerald glow
  const heroCardEl = document.getElementById('heroCard');
  if (heroCardEl) {
    animEngine.flashCard(heroCardEl, 'emerald');
  }

  // 5. Flash specific bucket card if on Goals view
  if (bucketId) {
    const bucketCardEl = document.getElementById(`bucketCard_${bucketId}`);
    if (bucketCardEl) {
      animEngine.flashCard(bucketCardEl, 'emerald');
    }
  }

  // 6. Rapidly Morph and Tween Chart upwards
  if (savingsChart) {
    savingsChart.rapidAnimateDeposit(oldMonthSaved, newMonthSaved);
  }

  // 7. Update Donut Visualizer if visible
  if (donutViz) {
    donutViz.render();
  }

  // 8. Update Progress Bars
  updateProgressBars();

  // 9. Prepend Activity item with slide-in animation
  prependActivityItem(data.transaction);

  // 10. Check if Monthly Target was Reached (Celebration Confetti!)
  const currentGoal = store.getMonthGoal();
  if (oldMonthSaved < currentGoal && newMonthSaved >= currentGoal) {
    setTimeout(() => {
      animEngine.triggerConfetti();
    }, 400);
  }
}

// Update UI Progress Bars smoothly
function updateProgressBars() {
  const metrics = store.getOverallMetrics();
  const progressBar = document.getElementById('heroProgressBar');
  const progressText = document.getElementById('heroProgressText');

  if (progressBar) {
    progressBar.style.width = `${metrics.progressPercent}%`;
  }
  if (progressText) {
    progressText.textContent = `${metrics.progressPercent}% of Goal`;
  }
}

// Switch between Tabs: Dashboard, Monthly, Goals, History
function switchTab(tabId) {
  if (currentTab === tabId) return;
  currentTab = tabId;

  // Update tab bar buttons
  document.querySelectorAll('.tab-item').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.tab === tabId);
  });

  animEngine.haptic([10]);
  renderCurrentView();
}

function renderNavigation() {
  const tabs = [
    { id: 'dashboard', name: 'Dashboard', icon: 'wallet' },
    { id: 'monthly', name: 'Monthly', icon: 'calendar' },
    { id: 'goals', name: 'Buckets', icon: 'target' },
    { id: 'history', name: 'Activity', icon: 'trendingUp' }
  ];

  const tabBar = document.getElementById('tabBar');
  if (!tabBar) return;

  tabBar.innerHTML = tabs.map(t => `
    <button class="tab-item btn-press ${t.id === currentTab ? 'active' : ''}" data-tab="${t.id}" onclick="switchTab('${t.id}')">
      ${getIcon(t.icon, 'w-5 h-5 mb-0.5', 20)}
      <span>${t.name}</span>
    </button>
  `).join('');
}

// Render active tab view
function renderCurrentView() {
  const container = document.getElementById('appContent');
  if (!container) return;

  switch (currentTab) {
    case 'dashboard':
      renderDashboardView(container);
      break;
    case 'monthly':
      renderMonthlyView(container);
      break;
    case 'goals':
      renderGoalsView(container);
      break;
    case 'history':
      renderHistoryView(container);
      break;
    default:
      renderDashboardView(container);
  }
}

// ==========================================
// 1. DASHBOARD VIEW
// ==========================================
function renderDashboardView(container) {
  const metrics = store.getOverallMetrics();
  const currency = metrics.currency;
  const isPositiveMom = metrics.momRate >= 0;

  container.innerHTML = `
    <!-- Top Greeting & Action Header -->
    <div class="flex items-center justify-between mb-4">
      <div>
        <span class="text-xs font-semibold text-emerald-400 tracking-wide uppercase flex items-center gap-1.5">
          ${getIcon('sparkles', 'text-emerald-400', 14)}
          Wealth Growth
        </span>
        <h1 class="text-2xl font-extrabold text-white tracking-tight">Overview</h1>
      </div>
      <button class="btn-secondary btn-press text-xs px-3 py-1.5" onclick="openAddModal()">
        ${getIcon('plus', 'w-3.5 h-3.5 text-emerald-400', 14)}
        <span>Deposit</span>
      </button>
    </div>

    <!-- HERO SAVINGS CARD (Separate Dashboard Hero) -->
    <div id="heroCard" class="glass-card hero-card mb-5">
      <div class="flex items-start justify-between">
        <div>
          <span class="text-xs font-medium text-slate-400 uppercase tracking-wider block mb-1">Total Accumulated Savings</span>
          <div class="text-3xl font-black text-white tracking-tight flex items-baseline">
            <span id="heroTotalSavings" class="tabular-nums">${currency}${metrics.totalSavings.toLocaleString('en-IN')}</span>
          </div>
        </div>
        <div class="pill-badge ${isPositiveMom ? 'pill-badge-emerald' : 'pill-badge-blue'} flex-shrink-0">
          ${getIcon(isPositiveMom ? 'trendingUp' : 'calendar', 'w-3.5 h-3.5', 14)}
          <span>${isPositiveMom ? '+' : ''}${metrics.momRate}% MoM</span>
        </div>
      </div>

      <!-- Current Month Target Progress (Rock-solid Layout) -->
      <div class="mt-4 pt-3.5 border-t border-white/10">
        <div class="flex items-baseline justify-between mb-1.5 text-xs">
          <div class="flex items-center gap-1.5 min-w-0">
            ${getIcon('calendar', 'text-emerald-400 flex-shrink-0', 14)}
            <span class="text-slate-300 font-semibold truncate">September Savings</span>
          </div>
          <div class="text-right flex-shrink-0">
            <span id="heroMonthSavings" class="text-white font-extrabold tabular-nums">${currency}${metrics.currentMonthSaved.toLocaleString('en-IN')}</span>
            <span class="text-[11px] text-slate-400 font-normal"> / ${currency}${metrics.currentGoal.toLocaleString('en-IN')}</span>
          </div>
        </div>

        <!-- Modern Rounded Progress Bar -->
        <div class="w-full h-2.5 bg-black/40 rounded-full overflow-hidden border border-white/5 relative my-2">
          <div id="heroProgressBar" class="h-full bg-gradient-to-r from-emerald-500 to-teal-400 rounded-full transition-all duration-700 ease-out" style="width: ${metrics.progressPercent}%;"></div>
        </div>

        <div class="flex items-center justify-between text-[11px] text-slate-400">
          <span>Target: ${currency}${metrics.currentGoal.toLocaleString('en-IN')}</span>
          <span id="heroProgressText" class="text-emerald-400 font-bold">${metrics.progressPercent}% of Goal</span>
        </div>
      </div>

      <!-- Quick Add CTA Inside Hero -->
      <div class="mt-4 flex gap-2">
        <button class="flex-1 btn-primary btn-press text-xs py-2.5 whitespace-nowrap" onclick="quickAddAmount(1000)">
          <span>+${currency}1,000 Quick Add</span>
        </button>
        <button class="flex-1 btn-secondary btn-press text-xs py-2.5 whitespace-nowrap" onclick="quickAddAmount(2500)">
          <span>+${currency}2,500</span>
        </button>
      </div>
    </div>

    <!-- INTERACTIVE GRAPH CARD -->
    <div class="glass-card mb-5">
      <div class="flex items-center justify-between mb-3">
        <div class="flex items-center gap-2">
          <div class="p-1.5 rounded-lg bg-emerald-500/10 text-emerald-400">
            ${getIcon('trendingUp', 'w-4 h-4', 16)}
          </div>
          <div>
            <h2 class="text-sm font-bold text-white">Savings Trajectory</h2>
            <p class="text-[10px] text-slate-400">Monthly progression vs target</p>
          </div>
        </div>

        <!-- Segmented Control for Timeframe -->
        <div class="segmented-control">
          <button class="segment-btn ${savingsChart && savingsChart.timeframe === '3M' ? 'active' : ''}" onclick="setTimeframe('3M', this)">3M</button>
          <button class="segment-btn ${!savingsChart || savingsChart.timeframe === '6M' ? 'active' : ''}" onclick="setTimeframe('6M', this)">6M</button>
          <button class="segment-btn ${savingsChart && savingsChart.timeframe === '1Y' ? 'active' : ''}" onclick="setTimeframe('1Y', this)">1Y</button>
        </div>
      </div>

      <!-- Chart Container -->
      <div id="chartContainer" class="w-full relative"></div>
    </div>

    <!-- CATEGORY ALLOCATION CARD (Donut Graph) -->
    <div class="glass-card mb-5">
      <div class="flex items-center justify-between mb-3">
        <div class="flex items-center gap-2">
          <div class="p-1.5 rounded-lg bg-blue-500/10 text-blue-400">
            ${getIcon('pieChart', 'w-4 h-4', 16)}
          </div>
          <div>
            <h2 class="text-sm font-bold text-white">Asset Allocation</h2>
            <p class="text-[10px] text-slate-400">Distribution across savings buckets</p>
          </div>
        </div>
        <button class="text-xs text-emerald-400 font-semibold flex items-center gap-1" onclick="switchTab('goals')">
          <span>Manage</span>
          ${getIcon('chevronRight', 'w-3.5 h-3.5', 14)}
        </button>
      </div>

      <!-- Donut Visualizer Container -->
      <div id="donutContainer"></div>
    </div>

    <!-- KEY FINANCIAL METRICS GRID -->
    <div class="grid grid-cols-2 gap-3 mb-5">
      <div class="glass-card p-3.5">
        <span class="text-[10px] font-medium text-slate-400 uppercase tracking-wider block mb-1">Monthly Average</span>
        <div class="text-base font-extrabold text-white">${currency}${metrics.avgMonthly.toLocaleString('en-IN')}<span class="text-xs text-slate-400 font-normal">/mo</span></div>
        <span class="text-[10px] text-slate-500 block mt-1">Based on historical data</span>
      </div>

      <div class="glass-card p-3.5">
        <span class="text-[10px] font-medium text-slate-400 uppercase tracking-wider block mb-1">Projected Annual</span>
        <div class="text-base font-extrabold text-emerald-400">${currency}${metrics.projectedAnnual.toLocaleString('en-IN')}</div>
        <span class="text-[10px] text-slate-500 block mt-1">Estimated year-end total</span>
      </div>
    </div>

    <!-- RECENT TRANSACTIONS PREVIEW -->
    <div class="mb-4">
      <div class="flex items-center justify-between mb-2.5">
        <h2 class="text-sm font-bold text-white">Recent Deposits</h2>
        <button class="text-xs text-slate-400 hover:text-white" onclick="switchTab('history')">See All</button>
      </div>
      <div id="recentActivityList">
        ${renderActivityListHTML(store.state.transactions.slice(0, 3))}
      </div>
    </div>
  `;

  // Initialize interactive SVG chart and donut visualizer
  setTimeout(() => {
    savingsChart = new SavingsChart('chartContainer');
    donutViz = new DonutVisualizer('donutContainer');
  }, 0);
}

function setTimeframe(tf, btn) {
  animEngine.haptic([10]);
  document.querySelectorAll('.segment-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  if (savingsChart) {
    savingsChart.setTimeframe(tf);
  }
}

// ==========================================
// 2. MONTHLY BREAKDOWN VIEW
// ==========================================
function renderMonthlyView(container) {
  const currentPeriod = store.getCurrentPeriod();
  const history = store.state.monthlyHistory;
  const currency = store.state.settings.currency;
  const months = Object.keys(history).sort().reverse();

  container.innerHTML = `
    <div class="flex items-center justify-between mb-4">
      <div>
        <span class="text-xs font-semibold text-emerald-400 tracking-wide uppercase">Performance</span>
        <h1 class="text-2xl font-extrabold text-white tracking-tight">Monthly Archive</h1>
      </div>
      <button class="btn-primary btn-press text-xs px-3.5 py-2" onclick="openAddModal()">
        ${getIcon('plus', 'w-3.5 h-3.5', 14)}
        <span>Add Savings</span>
      </button>
    </div>

    <!-- Month Selector Cards -->
    <div class="space-y-3">
      ${months.map(p => {
        const item = history[p];
        const [year, month] = p.split('-');
        const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        const mName = monthNames[parseInt(month, 10) - 1];
        const pct = Math.min(100, Math.round((item.saved / item.goal) * 100));
        const isCurrent = p === currentPeriod;

        return `
          <div class="glass-card ${isCurrent ? 'border-emerald-500/40 bg-emerald-950/10' : ''}">
            <div class="flex items-center justify-between mb-2">
              <div>
                <div class="flex items-center gap-2">
                  <h3 class="font-bold text-white text-base">${mName} ${year}</h3>
                  ${isCurrent ? '<span class="pill-badge pill-badge-emerald text-[9px] py-0.5">CURRENT</span>' : ''}
                </div>
                <span class="text-xs text-slate-400">Target: ${currency}${item.goal.toLocaleString('en-IN')}</span>
              </div>
              <div class="text-right">
                <div class="text-lg font-black text-emerald-400">${currency}${item.saved.toLocaleString('en-IN')}</div>
                <span class="text-[11px] font-semibold text-slate-300">${pct}% Saved</span>
              </div>
            </div>

            <div class="w-full h-2 bg-black/40 rounded-full overflow-hidden border border-white/5">
              <div class="h-full bg-gradient-to-r from-emerald-500 to-teal-400 rounded-full" style="width: ${pct}%;"></div>
            </div>
          </div>
        `;
      }).join('')}
    </div>
  `;
}

// ==========================================
// 3. SAVINGS BUCKETS & GOALS VIEW
// ==========================================
function renderGoalsView(container) {
  const buckets = store.state.buckets;
  const currency = store.state.settings.currency;

  container.innerHTML = `
    <div class="flex items-center justify-between mb-4">
      <div>
        <span class="text-xs font-semibold text-emerald-400 tracking-wide uppercase">Goals & Buckets</span>
        <h1 class="text-2xl font-extrabold text-white tracking-tight">Dedicated Funds</h1>
      </div>
      <button class="btn-primary btn-press text-xs px-3.5 py-2" onclick="openAddModal()">
        ${getIcon('plus', 'w-3.5 h-3.5', 14)}
        <span>New Deposit</span>
      </button>
    </div>

    <div class="space-y-3.5">
      ${buckets.map(b => {
        const pct = Math.min(100, Math.round((b.current / b.target) * 100));
        return `
          <div id="bucketCard_${b.id}" class="glass-card">
            <div class="flex items-start justify-between mb-3">
              <div class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-2xl flex items-center justify-center text-white" style="background: ${b.color}20; color: ${b.color}; border: 1px solid ${b.color}40;">
                  ${getIcon(b.icon, 'w-5 h-5', 20)}
                </div>
                <div>
                  <h3 class="font-bold text-white text-base leading-tight">${b.name}</h3>
                  <span class="text-xs text-slate-400">${b.category}</span>
                </div>
              </div>
              <button class="btn-secondary btn-press text-xs py-1 px-2.5 flex items-center gap-1" onclick="openAddModal('${b.id}')">
                ${getIcon('plus', 'w-3 h-3 text-emerald-400', 12)}
                <span>Deposit</span>
              </button>
            </div>

            <div class="flex items-baseline justify-between text-xs mb-1.5">
              <span class="text-slate-300 font-medium">Saved: <strong class="text-white">${currency}${b.current.toLocaleString('en-IN')}</strong></span>
              <span class="font-bold" style="color: ${b.color};">${pct}%</span>
            </div>

            <!-- Goal progress bar -->
            <div class="w-full h-2.5 bg-black/40 rounded-full overflow-hidden border border-white/5 mb-2">
              <div class="h-full rounded-full transition-all duration-700 ease-out" style="width: ${pct}%; background-color: ${b.color};"></div>
            </div>

            <div class="flex justify-between items-center text-[11px] text-slate-400">
              <span>Target: ${currency}${b.target.toLocaleString('en-IN')}</span>
              <span>Remaining: ${currency}${Math.max(0, b.target - b.current).toLocaleString('en-IN')}</span>
            </div>
          </div>
        `;
      }).join('')}
    </div>
  `;
}

// ==========================================
// 4. ACTIVITY & SETTINGS VIEW
// ==========================================
function renderHistoryView(container) {
  const transactions = store.state.transactions;
  const currency = store.state.settings.currency;

  container.innerHTML = `
    <div class="flex items-center justify-between mb-4">
      <div>
        <span class="text-xs font-semibold text-emerald-400 tracking-wide uppercase">Audit Log</span>
        <h1 class="text-2xl font-extrabold text-white tracking-tight">Activity</h1>
      </div>
      <button class="btn-secondary btn-press text-xs px-3 py-1.5" onclick="exportData()">
        ${getIcon('arrowUpRight', 'w-3.5 h-3.5', 14)}
        <span>Export</span>
      </button>
    </div>

    <!-- Currency & Quick Settings -->
    <div class="glass-card mb-4 p-3.5">
      <span class="text-xs font-bold text-white block mb-2">Preferences</span>
      <div class="flex items-center justify-between text-xs mb-3">
        <span class="text-slate-300">Currency Symbol</span>
        <div class="flex gap-1.5">
          ${['₹', '$', '€', '£'].map(cur => `
            <button class="amount-chip py-1 px-2.5 text-xs ${currency === cur ? 'selected' : ''}" onclick="changeCurrency('${cur}')">${cur}</button>
          `).join('')}
        </div>
      </div>
      <div class="flex items-center justify-between text-xs pt-2 border-t border-white/5">
        <span class="text-slate-300">Audio Feedback</span>
        <button class="text-emerald-400 font-bold" onclick="toggleSound()">
          ${store.state.settings.soundEnabled ? 'Enabled' : 'Disabled'}
        </button>
      </div>
    </div>

    <div class="mb-3 flex items-center justify-between">
      <span class="text-xs font-bold text-slate-300 uppercase tracking-wider">All Transactions (${transactions.length})</span>
      <button class="text-[11px] text-rose-400 hover:text-rose-300 font-semibold" onclick="confirmReset()">Reset Sample Data</button>
    </div>

    <div id="fullActivityList">
      ${renderActivityListHTML(transactions, true)}
    </div>
  `;
}

// Render Activity items HTML
function renderActivityListHTML(transactions, showDelete = false) {
  if (!transactions || transactions.length === 0) {
    return `
      <div class="text-center py-8 text-slate-500 text-xs">
        No savings deposits recorded yet.
      </div>
    `;
  }

  const currency = store.state.settings.currency;

  return transactions.map(tx => {
    const d = new Date(tx.date);
    const dateStr = isNaN(d.getTime()) ? tx.date : d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });

    return `
      <div id="tx_${tx.id}" class="activity-item">
        <div class="flex items-center gap-3">
          <div class="w-9 h-9 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center border border-emerald-500/20">
            ${getIcon('plus', 'w-4 h-4', 16)}
          </div>
          <div>
            <span class="font-bold text-white text-xs block">${tx.note || 'Savings Deposit'}</span>
            <span class="text-[11px] text-slate-400">${tx.bucketName} • ${dateStr}</span>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <span class="font-extrabold text-sm text-emerald-400">+${currency}${tx.amount.toLocaleString('en-IN')}</span>
          ${showDelete ? `
            <button class="text-slate-500 hover:text-rose-400 p-1" onclick="deleteTx('${tx.id}')">
              ${getIcon('trash', 'w-3.5 h-3.5', 14)}
            </button>
          ` : ''}
        </div>
      </div>
    `;
  }).join('');
}

function prependActivityItem(tx) {
  const recentList = document.getElementById('recentActivityList');
  const fullList = document.getElementById('fullActivityList');
  const currency = store.state.settings.currency;
  const d = new Date(tx.date);
  const dateStr = d.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });

  const html = `
    <div id="tx_${tx.id}" class="activity-item activity-item-new">
      <div class="flex items-center gap-3">
        <div class="w-9 h-9 rounded-xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center border border-emerald-500/20">
          ${getIcon('plus', 'w-4 h-4', 16)}
        </div>
        <div>
          <span class="font-bold text-white text-xs block">${tx.note || 'Savings Deposit'}</span>
          <span class="text-[11px] text-slate-400">${tx.bucketName} • ${dateStr}</span>
        </div>
      </div>
      <div class="flex items-center gap-2">
        <span class="font-extrabold text-sm text-emerald-400">+${currency}${tx.amount.toLocaleString('en-IN')}</span>
      </div>
    </div>
  `;

  if (recentList) {
    recentList.insertAdjacentHTML('afterbegin', html);
  }
  if (fullList) {
    fullList.insertAdjacentHTML('afterbegin', html);
  }
}

// ==========================================
// 5. MODAL BOTTOM SHEET (ADD MONEY FLOW)
// ==========================================
let selectedBucketId = 'emergency';
let selectedAmount = 1000;

function setupModalSheet() {
  const backdrop = document.getElementById('modalBackdrop');
  const sheet = document.getElementById('bottomSheet');
  if (backdrop) {
    backdrop.addEventListener('click', closeAddModal);
  }
}

function openAddModal(defaultBucketId = null) {
  animEngine.haptic([10]);
  if (defaultBucketId) {
    selectedBucketId = defaultBucketId;
  }

  const backdrop = document.getElementById('modalBackdrop');
  const sheet = document.getElementById('bottomSheet');
  const buckets = store.state.buckets;
  const currency = store.state.settings.currency;

  const content = document.getElementById('modalSheetContent');
  content.innerHTML = `
    <div class="sheet-handle"></div>
    <div class="flex items-center justify-between mb-4">
      <div>
        <h2 class="text-lg font-bold text-white">Add Monthly Savings</h2>
        <p class="text-xs text-slate-400">Instantly grow your reserves</p>
      </div>
      <button class="p-2 text-slate-400 hover:text-white" onclick="closeAddModal()">
        ${getIcon('x', 'w-5 h-5', 20)}
      </button>
    </div>

    <!-- Quick Denominations Pills -->
    <div class="mb-4">
      <span class="text-xs font-semibold text-slate-400 block mb-2">Select Amount</span>
      <div class="grid grid-cols-4 gap-2 mb-3">
        ${[500, 1000, 2500, 5000].map(amt => `
          <button class="amount-chip btn-press ${amt === selectedAmount ? 'selected' : ''}" onclick="selectChipAmount(${amt}, this)">
            +${currency}${amt.toLocaleString('en-IN')}
          </button>
        `).join('')}
      </div>

      <!-- Custom Amount Input -->
      <div class="relative">
        <span class="absolute left-4 top-1/2 -translate-y-1/2 text-lg font-bold text-emerald-400">${currency}</span>
        <input
          id="customAmountInput"
          type="number"
          step="100"
          value="${selectedAmount}"
          placeholder="Custom amount"
          class="w-full bg-black/40 border border-white/10 rounded-2xl py-3.5 pl-9 pr-4 text-white text-lg font-extrabold focus:outline-none focus:border-emerald-500 transition-colors"
        />
      </div>
    </div>

    <!-- Destination Savings Bucket -->
    <div class="mb-5">
      <span class="text-xs font-semibold text-slate-400 block mb-2">Allocate to Bucket</span>
      <div class="grid grid-cols-2 gap-2">
        ${buckets.map(b => `
          <button class="bucket-pill btn-press ${b.id === selectedBucketId ? 'selected' : ''}" onclick="selectBucket('${b.id}', this)">
            <span class="w-3 h-3 rounded-full flex-shrink-0" style="background-color: ${b.color};"></span>
            <span class="truncate">${b.name}</span>
          </button>
        `).join('')}
      </div>
    </div>

    <!-- Optional Note -->
    <div class="mb-5">
      <input
        id="depositNoteInput"
        type="text"
        placeholder="Note (e.g. Salary, Side hustle, Bonus)"
        class="w-full bg-black/30 border border-white/10 rounded-xl py-2.5 px-3 text-xs text-white placeholder:text-slate-500 focus:outline-none focus:border-emerald-500"
      />
    </div>

    <!-- Confirm Button -->
    <button id="confirmDepositBtn" class="w-full btn-primary btn-press text-sm py-4" onclick="confirmDeposit()">
      ${getIcon('checkCircle', 'w-4 h-4', 18)}
      <span>Confirm Deposit</span>
    </button>
  `;

  backdrop.classList.add('open');
  sheet.classList.add('open');

  // Sync custom input
  const input = document.getElementById('customAmountInput');
  if (input) {
    input.addEventListener('input', (e) => {
      selectedAmount = parseFloat(e.target.value) || 0;
      document.querySelectorAll('.amount-chip').forEach(c => c.classList.remove('selected'));
    });
  }
}

function closeAddModal() {
  const backdrop = document.getElementById('modalBackdrop');
  const sheet = document.getElementById('bottomSheet');
  if (backdrop) backdrop.classList.remove('open');
  if (sheet) sheet.classList.remove('open');
}

function selectChipAmount(amt, btn) {
  animEngine.haptic([10]);
  selectedAmount = amt;
  document.querySelectorAll('.amount-chip').forEach(c => c.classList.remove('selected'));
  btn.classList.add('selected');

  const input = document.getElementById('customAmountInput');
  if (input) {
    input.value = amt;
  }
}

function selectBucket(bId, btn) {
  animEngine.haptic([10]);
  selectedBucketId = bId;
  document.querySelectorAll('.bucket-pill').forEach(p => p.classList.remove('selected'));
  btn.classList.add('selected');
}

function quickAddAmount(amt) {
  animEngine.haptic([15]);
  store.addDeposit({
    amount: amt,
    bucketId: 'emergency',
    note: 'Quick Dashboard Deposit'
  });
}

function confirmDeposit() {
  const amountInput = document.getElementById('customAmountInput');
  const noteInput = document.getElementById('depositNoteInput');
  const amt = amountInput ? parseFloat(amountInput.value) : selectedAmount;
  const note = noteInput && noteInput.value.trim() ? noteInput.value.trim() : 'Manual Deposit';

  if (!amt || amt <= 0) {
    amountInput.focus();
    return;
  }

  // Pop button tactile animation
  const btn = document.getElementById('confirmDepositBtn');
  animEngine.popButton(btn);

  // Close sheet modal
  closeAddModal();

  // Trigger deposit in store
  store.addDeposit({
    amount: amt,
    bucketId: selectedBucketId,
    note: note
  });
}

// Settings & Helper Actions
function changeCurrency(sym) {
  animEngine.haptic([10]);
  store.updateCurrency(sym);
}

function toggleSound() {
  store.state.settings.soundEnabled = !store.state.settings.soundEnabled;
  store.saveState();
  renderCurrentView();
}

function deleteTx(id) {
  animEngine.haptic([15]);
  store.deleteTransaction(id);
}

function confirmReset() {
  if (confirm('Reset to standard sample savings data?')) {
    store.resetData();
  }
}

function exportData() {
  const json = store.exportJSON();
  const blob = new Blob([json], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `savings_tracker_backup_${new Date().toISOString().slice(0, 10)}.json`;
  a.click();
}

// Desktop Frame Toggle (Allows toggling between iPhone frame and Fullscreen on Kali Linux)
function setupDesktopControls() {
  const toggleBtn = document.getElementById('toggleFrameBtn');
  const device = document.getElementById('deviceContainer');
  if (!toggleBtn || !device) return;

  toggleBtn.addEventListener('click', () => {
    device.classList.toggle('max-w-[440px]');
    device.classList.toggle('max-w-4xl');
    device.classList.toggle('border-none');
    device.classList.toggle('rounded-none');
    toggleBtn.textContent = device.classList.contains('max-w-4xl') ? 'Switch to iPhone View' : 'Switch to Expanded View';
  });
}
