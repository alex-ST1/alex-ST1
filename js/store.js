// Store & State Management with LocalStorage & Reactive Subscriptions (INR • ₹ Optimized)
class SavingsStore {
  constructor() {
    this.STORAGE_KEY = 'ios_savings_tracker_data_v2';
    this.listeners = [];
    this.state = this.loadState();
  }

  getDefaultData() {
    return {
      settings: {
        currency: '₹',
        monthlyGoal: 25000,
        userName: 'Alex',
        soundEnabled: true,
        hapticEnabled: true
      },
      currentPeriod: '2026-09',
      // Monthly summary history in INR (₹)
      monthlyHistory: {
        '2026-01': { saved: 18000, goal: 20000, income: 65000, expenses: 47000 },
        '2026-02': { saved: 22000, goal: 20000, income: 65000, expenses: 43000 },
        '2026-03': { saved: 25000, goal: 25000, income: 70000, expenses: 45000 },
        '2026-04': { saved: 21000, goal: 25000, income: 68000, expenses: 47000 },
        '2026-05': { saved: 28000, goal: 25000, income: 75000, expenses: 47000 },
        '2026-06': { saved: 30000, goal: 25000, income: 78000, expenses: 48000 },
        '2026-07': { saved: 26000, goal: 25000, income: 72000, expenses: 46000 },
        '2026-08': { saved: 32000, goal: 25000, income: 80000, expenses: 48000 },
        '2026-09': { saved: 18500, goal: 25000, income: 75000, expenses: 56500 }
      },
      buckets: [
        {
          id: 'emergency',
          name: 'Emergency Fund',
          target: 200000,
          current: 145000,
          color: '#10b981', // emerald
          icon: 'shield',
          category: 'Safety'
        },
        {
          id: 'investments',
          name: 'Mutual Funds & SIP',
          target: 150000,
          current: 95000,
          color: '#3b82f6', // blue
          icon: 'trendingUp',
          category: 'Wealth'
        },
        {
          id: 'travel',
          name: 'Goa & Ladakh Trip',
          target: 60000,
          current: 42000,
          color: '#06b6d4', // cyan
          icon: 'plane',
          category: 'Leisure'
        },
        {
          id: 'tech',
          name: 'Workstation & Tech',
          target: 50000,
          current: 32000,
          color: '#a855f7', // purple
          icon: 'laptop',
          category: 'Gadgets'
        }
      ],
      transactions: [
        {
          id: 'tx_1',
          date: '2026-09-04T10:15:00',
          amount: 5000,
          bucketId: 'emergency',
          bucketName: 'Emergency Fund',
          note: 'Monthly salary allocation'
        },
        {
          id: 'tx_2',
          date: '2026-09-03T18:40:00',
          amount: 2500,
          bucketId: 'travel',
          bucketName: 'Goa & Ladakh Trip',
          note: 'Weekend savings deposit'
        },
        {
          id: 'tx_3',
          date: '2026-09-02T14:20:00',
          amount: 6000,
          bucketId: 'investments',
          bucketName: 'Mutual Funds & SIP',
          note: 'Monthly SIP auto-debit'
        },
        {
          id: 'tx_4',
          date: '2026-08-30T11:00:00',
          amount: 3500,
          bucketId: 'tech',
          bucketName: 'Workstation & Tech',
          note: 'Freelance project milestone'
        },
        {
          id: 'tx_5',
          date: '2026-08-28T09:30:00',
          amount: 8000,
          bucketId: 'emergency',
          bucketName: 'Emergency Fund',
          note: 'Performance bonus'
        }
      ]
    };
  }

  loadState() {
    try {
      // Check v2 first
      let saved = localStorage.getItem(this.STORAGE_KEY);

      // Seamless migration from v1 (convert $ to ₹)
      if (!saved) {
        const v1 = localStorage.getItem('ios_savings_tracker_data_v1');
        if (v1) {
          try {
            const parsedV1 = JSON.parse(v1);
            if (parsedV1.settings) {
              parsedV1.settings.currency = '₹';
            }
            saved = JSON.stringify(parsedV1);
            localStorage.setItem(this.STORAGE_KEY, saved);
          } catch (e) {}
        }
      }

      if (saved) {
        const state = JSON.parse(saved);
        // Ensure default is INR (₹)
        if (state.settings && (!state.settings.currency || state.settings.currency === '$')) {
          state.settings.currency = '₹';
          this.saveState(state);
        }
        return state;
      }
    } catch (e) {
      console.warn('Could not read from localStorage, using default INR data:', e);
    }
    const defaultData = this.getDefaultData();
    this.saveState(defaultData);
    return defaultData;
  }

  saveState(state = this.state) {
    try {
      localStorage.setItem(this.STORAGE_KEY, JSON.stringify(state));
    } catch (e) {
      console.error('Failed to save to localStorage:', e);
    }
  }

  subscribe(listener) {
    this.listeners.push(listener);
    return () => {
      this.listeners = this.listeners.filter(l => l !== listener);
    };
  }

  notify(event, payload) {
    this.listeners.forEach(fn => {
      try {
        fn(event, payload);
      } catch (e) {
        console.error('Listener callback error:', e);
      }
    });
  }

  // Format amount with Indian locale
  formatAmount(num) {
    const sym = this.state.settings.currency || '₹';
    const n = Math.round(parseFloat(num) || 0);
    return `${sym}${n.toLocaleString('en-IN')}`;
  }

  // Get current period (YYYY-MM)
  getCurrentPeriod() {
    return this.state.currentPeriod || '2026-09';
  }

  // Add savings entry (Rapid Refresh Trigger)
  addDeposit({ amount, bucketId, note, date = new Date().toISOString() }) {
    const numAmount = parseFloat(amount);
    if (isNaN(numAmount) || numAmount <= 0) return false;

    // Derive period from date (e.g. "2026-08")
    const dateObj = new Date(date);
    const period = !isNaN(dateObj.getTime())
      ? dateObj.toISOString().slice(0, 7)
      : this.getCurrentPeriod();
    const oldTotal = this.getTotalSavings();
    const oldMonthSaved = this.getMonthSaved(period);

    // 1. Update Monthly History
    const totalBucketTargets = this.state.buckets.reduce((acc, b) => acc + (b.target || 0), 0);
    const targetGoal = totalBucketTargets > 0 ? totalBucketTargets : this.state.settings.monthlyGoal;
    if (!this.state.monthlyHistory[period]) {
      this.state.monthlyHistory[period] = {
        saved: 0,
        goal: targetGoal,
        income: 75000,
        expenses: 50000
      };
    }
    this.state.monthlyHistory[period].saved += numAmount;
    if (this.state.monthlyHistory[period].goal === 0 && targetGoal > 0) {
      this.state.monthlyHistory[period].goal = targetGoal;
    }

    // 2. Update specific bucket if provided
    let targetBucket = null;
    if (bucketId) {
      targetBucket = this.state.buckets.find(b => b.id === bucketId);
      if (targetBucket) {
        targetBucket.current += numAmount;
      }
    }

    // 3. Create transaction entry
    const newTx = {
      id: 'tx_' + Date.now(),
      date: date,
      amount: numAmount,
      bucketId: bucketId || 'general',
      bucketName: targetBucket ? targetBucket.name : 'General Savings',
      note: note || 'Quick Deposit'
    };
    this.state.transactions.unshift(newTx);

    // Save to localStorage
    this.saveState();

    const newTotal = this.getTotalSavings();
    const newMonthSaved = this.getMonthSaved(period);

    // Notify listeners with rich metadata for animations
    this.notify('DEPOSIT_ADDED', {
      amount: numAmount,
      oldTotal,
      newTotal,
      oldMonthSaved,
      newMonthSaved,
      bucketId,
      bucket: targetBucket,
      transaction: newTx,
      period
    });

    return true;
  }

  // Calculate total overall savings across all buckets
  getTotalSavings() {
    return this.state.buckets.reduce((acc, b) => acc + (b.current || 0), 0);
  }

  getMonthSaved(period = this.getCurrentPeriod()) {
    const rec = this.state.monthlyHistory[period];
    return rec ? rec.saved : 0;
  }

  getMonthGoal(period = this.getCurrentPeriod()) {
    const rec = this.state.monthlyHistory[period];
    return rec ? rec.goal : this.state.settings.monthlyGoal;
  }

  updateMonthlyGoal(amount, period = this.getCurrentPeriod()) {
    const num = parseFloat(amount);
    if (isNaN(num) || num <= 0) return;
    this.state.settings.monthlyGoal = num;
    if (this.state.monthlyHistory[period]) {
      this.state.monthlyHistory[period].goal = num;
    }
    this.saveState();
    this.notify('GOAL_UPDATED', { goal: num, period });
  }

  updateCurrency(symbol) {
    this.state.settings.currency = symbol;
    this.saveState();
    this.notify('SETTINGS_UPDATED', this.state.settings);
  }

  getOverallMetrics() {
    const totalSavings = this.getTotalSavings();
    const totalBucketTargets = this.state.buckets.reduce((acc, b) => acc + (b.target || 0), 0);
    const currentPeriod = this.getCurrentPeriod();
    const currentMonthSaved = this.getMonthSaved(currentPeriod);
    const currentGoal = totalBucketTargets > 0 ? totalBucketTargets : this.getMonthGoal(currentPeriod);
    const progressPercent = currentGoal > 0
      ? Math.min(100, Math.round(((totalBucketTargets > 0 ? totalSavings : currentMonthSaved) / currentGoal) * 100))
      : 0;

    // Calculate Month-over-Month change
    const months = Object.keys(this.state.monthlyHistory).sort();
    const curIdx = months.indexOf(currentPeriod);
    let prevMonthSaved = 0;
    let momRate = 0;
    if (curIdx > 0) {
      const prevPeriod = months[curIdx - 1];
      prevMonthSaved = this.state.monthlyHistory[prevPeriod].saved;
      if (prevMonthSaved > 0) {
        momRate = Math.round(((currentMonthSaved - prevMonthSaved) / prevMonthSaved) * 100);
      }
    }

    // Monthly average
    const totalHistoricalSavings = Object.values(this.state.monthlyHistory).reduce((sum, m) => sum + m.saved, 0);
    const avgMonthly = months.length > 0 ? Math.round(totalHistoricalSavings / months.length) : 0;

    // Highest month
    let highestMonth = { period: '', saved: 0 };
    Object.entries(this.state.monthlyHistory).forEach(([period, data]) => {
      if (data.saved > highestMonth.saved) {
        highestMonth = { period, saved: data.saved };
      }
    });

    // Projected year-end savings (assuming remaining 3 months hit average)
    const projectedAnnual = totalHistoricalSavings + (avgMonthly * 3);

    return {
      totalSavings,
      currentMonthSaved,
      currentGoal,
      progressPercent,
      prevMonthSaved,
      momRate,
      avgMonthly,
      highestMonth,
      projectedAnnual,
      currency: this.state.settings.currency
    };
  }

  getChartData(timeframe = '6M') {
    const allMonths = Object.keys(this.state.monthlyHistory).sort();
    let selectedMonths = allMonths;

    if (timeframe === '3M') {
      selectedMonths = allMonths.slice(-3);
    } else if (timeframe === '6M') {
      selectedMonths = allMonths.slice(-6);
    } else if (timeframe === '1Y') {
      selectedMonths = allMonths.slice(-12);
    }

    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return selectedMonths.map(period => {
      const [year, month] = period.split('-');
      const mIdx = parseInt(month, 10) - 1;
      const data = this.state.monthlyHistory[period];
      return {
        period,
        label: `${monthNames[mIdx]} '${year.slice(2)}`,
        shortMonth: monthNames[mIdx],
        saved: data ? data.saved : 0,
        goal: data ? data.goal : 25000
      };
    });
  }

  getCategoryBreakdown() {
    const total = this.getTotalSavings();
    return this.state.buckets.map(b => {
      const pct = total > 0 ? Math.round((b.current / total) * 100) : 0;
      return {
        id: b.id,
        name: b.name,
        category: b.category,
        current: b.current,
        target: b.target,
        color: b.color,
        icon: b.icon,
        percentage: pct
      };
    });
  }

  deleteTransaction(id) {
    const tx = this.state.transactions.find(t => t.id === id);
    if (!tx) return;

    if (tx.bucketId) {
      const b = this.state.buckets.find(bucket => bucket.id === tx.bucketId);
      if (b) {
        b.current = Math.max(0, b.current - tx.amount);
      }
    }

    const period = tx.date.slice(0, 7);
    if (this.state.monthlyHistory[period]) {
      this.state.monthlyHistory[period].saved = Math.max(0, this.state.monthlyHistory[period].saved - tx.amount);
    }

    this.state.transactions = this.state.transactions.filter(t => t.id !== id);
    this.saveState();
    this.notify('DATA_RESET', {});
  }

  resetData() {
    this.state = this.getDefaultData();
    this.saveState();
    this.notify('DATA_RESET', {});
  }

  exportJSON() {
    return JSON.stringify(this.state, null, 2);
  }

  importJSON(jsonString) {
    try {
      const parsed = JSON.parse(jsonString);
      if (parsed && parsed.buckets && parsed.monthlyHistory) {
        this.state = parsed;
        this.saveState();
        this.notify('DATA_RESET', {});
        return true;
      }
    } catch (e) {
      console.error('Import failed:', e);
    }
    return false;
  }
}

const store = new SavingsStore();
