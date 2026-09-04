// Interactive Chart Engine: Smooth Bezier Splines, Dynamic Morphing & Donut Visualizer
class SavingsChart {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    this.timeframe = '6M';
    this.currentData = [];
    this.animating = false;
    this.activePointIndex = null;
    this.init();
  }

  init() {
    if (!this.container) return;
    this.render();

    window.addEventListener('resize', () => {
      this.render();
    });
  }

  setTimeframe(tf) {
    this.timeframe = tf;
    this.render();
  }

  // Generate smooth cubic bezier path string from points
  getSplinePath(points) {
    if (points.length < 2) return '';
    let d = `M ${points[0].x} ${points[0].y}`;

    for (let i = 0; i < points.length - 1; i++) {
      const p0 = points[i === 0 ? 0 : i - 1];
      const p1 = points[i];
      const p2 = points[i + 1];
      const p3 = points[i + 2] || p2;

      // Tension calculation for smooth curve
      const cp1x = p1.x + (p2.x - p0.x) / 6;
      const cp1y = p1.y + (p2.y - p0.y) / 6;

      const cp2x = p2.x - (p3.x - p1.x) / 6;
      const cp2y = p2.y - (p3.y - p1.y) / 6;

      d += ` C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${p2.x} ${p2.y}`;
    }
    return d;
  }

  render(targetPoints = null) {
    if (!this.container) return;

    const data = store.getChartData(this.timeframe);
    this.currentData = data;

    const width = this.container.clientWidth || 340;
    const height = 190;
    const padTop = 28;
    const padBottom = 34;
    const padLeft = 18;
    const padRight = 18;

    const chartW = width - padLeft - padRight;
    const chartH = height - padTop - padBottom;

    const maxVal = Math.max(...data.map(d => Math.max(d.saved, d.goal)), 25000) * 1.15;
    const minVal = 0;

    // Calculate (x, y) for each data point
    const points = targetPoints || data.map((d, i) => {
      const x = padLeft + (i / (data.length - 1)) * chartW;
      const normY = (d.saved - minVal) / (maxVal - minVal);
      const y = padTop + chartH - (normY * chartH);
      return { x, y, data: d, index: i };
    });

    this.calculatedPoints = points;

    const linePath = this.getSplinePath(points);
    const firstPoint = points[0];
    const lastPoint = points[points.length - 1];
    const bottomY = padTop + chartH;

    // Area closed path for gradient
    const areaPath = `${linePath} L ${lastPoint.x} ${bottomY} L ${firstPoint.x} ${bottomY} Z`;

    // Goal reference line (horizontal dashed)
    const currentGoal = store.getMonthGoal();
    const goalNormY = (currentGoal - minVal) / (maxVal - minVal);
    const goalY = padTop + chartH - (goalNormY * chartH);

    const currency = store.state.settings.currency;

    // Build SVG markup
    let svg = `
      <svg viewBox="0 0 ${width} ${height}" class="w-full h-full overflow-visible" style="min-height: 190px;">
        <defs>
          <linearGradient id="savingsAreaGradient" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stop-color="#10b981" stop-opacity="0.38" />
            <stop offset="60%" stop-color="#10b981" stop-opacity="0.08" />
            <stop offset="100%" stop-color="#10b981" stop-opacity="0" />
          </linearGradient>

          <linearGradient id="savingsStrokeGradient" x1="0" y1="0" x2="1" y2="0">
            <stop offset="0%" stop-color="#059669" />
            <stop offset="50%" stop-color="#10b981" />
            <stop offset="100%" stop-color="#34d399" />
          </linearGradient>

          <filter id="glowFilter" x="-20%" y="-20%" width="140%" height="140%">
            <feGaussianBlur stdDeviation="4" result="blur" />
            <feComposite in="SourceGraphic" in2="blur" operator="over" />
          </filter>
        </defs>

        <!-- Background grid guides -->
        <line x1="${padLeft}" y1="${padTop + chartH * 0.25}" x2="${width - padRight}" y2="${padTop + chartH * 0.25}" stroke="rgba(255, 255, 255, 0.05)" stroke-dasharray="3,3" />
        <line x1="${padLeft}" y1="${padTop + chartH * 0.65}" x2="${width - padRight}" y2="${padTop + chartH * 0.65}" stroke="rgba(255, 255, 255, 0.05)" stroke-dasharray="3,3" />
        <line x1="${padLeft}" y1="${bottomY}" x2="${width - padRight}" y2="${bottomY}" stroke="rgba(255, 255, 255, 0.1)" />

        <!-- Goal Reference Line -->
        <g class="goal-line-group">
          <line x1="${padLeft}" y1="${goalY}" x2="${width - padRight}" y2="${goalY}" stroke="#f59e0b" stroke-width="1.2" stroke-dasharray="4,4" opacity="0.65" />
          <text x="${width - padRight}" y="${goalY - 5}" fill="#f59e0b" font-size="10" font-weight="600" text-anchor="end" opacity="0.85">Target ${currency}${currentGoal.toLocaleString('en-IN')}</text>
        </g>

        <!-- Filled Gradient Area -->
        <path id="chartAreaPath" d="${areaPath}" fill="url(#savingsAreaGradient)" />

        <!-- Spline Line -->
        <path id="chartSplinePath" d="${linePath}" fill="none" stroke="url(#savingsStrokeGradient)" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />

        <!-- Data Point Markers -->
        <g id="chartPointsGroup">
    `;

    // Render interactive circles
    points.forEach((p, idx) => {
      const isLast = idx === points.length - 1;
      const isSelected = this.activePointIndex === idx || (this.activePointIndex === null && isLast);

      svg += `
        <g class="chart-point-marker cursor-pointer" data-idx="${idx}" style="transition: transform 0.2s ease;">
          ${isLast ? `
            <!-- Pulsing outer ripple for current month -->
            <circle cx="${p.x}" cy="${p.y}" r="12" fill="#10b981" opacity="0.22" class="animate-pulse-slow" />
          ` : ''}

          <!-- Outer aura ring -->
          <circle cx="${p.x}" cy="${p.y}" r="${isSelected ? 7 : 5}" fill="#0a0d14" stroke="#10b981" stroke-width="${isSelected ? 2.5 : 1.8}" filter="url(#glowFilter)" />

          <!-- Center dot -->
          <circle cx="${p.x}" cy="${p.y}" r="${isSelected ? 3.5 : 2.5}" fill="${isSelected ? '#34d399' : '#ffffff'}" />

          <!-- Invisible touch target for easy tapping on iPhone -->
          <circle cx="${p.x}" cy="${p.y}" r="22" fill="transparent" />

          <!-- Month Label -->
          <text x="${p.x}" y="${bottomY + 20}" fill="${isSelected ? '#10b981' : '#94a3b8'}" font-size="11" font-weight="${isSelected ? '700' : '500'}" text-anchor="middle">
            ${p.data.shortMonth}
          </text>
        </g>
      `;
    });

    svg += `
        </g>
      </svg>
      <!-- Tooltip Overlay -->
      <div id="chartTooltip" class="chart-tooltip hidden"></div>
    `;

    this.container.innerHTML = svg;
    this.attachEvents();
  }

  attachEvents() {
    const markers = this.container.querySelectorAll('.chart-point-marker');
    const tooltip = this.container.querySelector('#chartTooltip');

    markers.forEach(m => {
      const showTip = () => {
        const idx = parseInt(m.getAttribute('data-idx'), 10);
        this.activePointIndex = idx;
        const p = this.calculatedPoints[idx];
        if (!p || !tooltip) return;

        const currency = store.state.settings.currency;
        tooltip.innerHTML = `
          <div class="font-bold text-xs text-white">${p.data.label}</div>
          <div class="text-sm font-extrabold text-emerald-400 mt-0.5">${currency}${p.data.saved.toLocaleString('en-IN')}</div>
          <div class="text-[10px] text-slate-400">Target: ${currency}${p.data.goal.toLocaleString('en-IN')}</div>
        `;
        tooltip.classList.remove('hidden');

        // Position tooltip relative to point
        const contRect = this.container.getBoundingClientRect();
        tooltip.style.left = `${p.x}px`;
        tooltip.style.top = `${Math.max(10, p.y - 48)}px`;
        tooltip.style.transform = 'translateX(-50%)';

        // Re-render highlight
        this.render();
      };

      m.addEventListener('mouseenter', showTip);
      m.addEventListener('click', (e) => {
        e.stopPropagation();
        animEngine.haptic([10]);
        showTip();
      });
    });
  }

  // Rapid Refresh Animation: Smoothly tweens the latest point up when money is deposited
  rapidAnimateDeposit(oldVal, newVal) {
    if (!this.calculatedPoints || this.calculatedPoints.length === 0) {
      this.render();
      return;
    }

    const duration = 850;
    const startTime = performance.now();
    const lastIdx = this.calculatedPoints.length - 1;

    // Calculate old and new target Y coordinates
    const height = 190;
    const padTop = 28;
    const padBottom = 34;
    const chartH = height - padTop - padBottom;
    const maxVal = Math.max(...this.currentData.map(d => Math.max(d.saved, d.goal)), newVal) * 1.15;
    const minVal = 0;

    const startY = padTop + chartH - ((oldVal - minVal) / (maxVal - minVal) * chartH);
    const targetY = padTop + chartH - ((newVal - minVal) / (maxVal - minVal) * chartH);

    const step = (time) => {
      const elapsed = time - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const eased = animEngine.easeOutQuint(progress);

      const currentY = startY + (targetY - startY) * eased;

      // Clone current points and update last point's Y
      const tweenedPoints = this.calculatedPoints.map((p, idx) => {
        if (idx === lastIdx) {
          return { ...p, y: currentY };
        }
        return p;
      });

      this.render(tweenedPoints);

      if (progress < 1) {
        requestAnimationFrame(step);
      } else {
        // Final render with true values
        this.render();
      }
    };

    requestAnimationFrame(step);
  }
}

// Category Breakdown Donut / Ring Visualizer
class DonutVisualizer {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    this.render();
  }

  render() {
    if (!this.container) return;
    const categories = store.getCategoryBreakdown();
    const total = store.getTotalSavings();
    const currency = store.state.settings.currency;

    const size = 126;
    const strokeWidth = 12;
    const radius = (size - strokeWidth) / 2;
    const circumference = 2 * Math.PI * radius;

    let accumulatedOffset = 0;
    let circleSegments = '';

    categories.forEach(cat => {
      const ratio = total > 0 ? cat.current / total : 0;
      const strokeDash = ratio * circumference;
      const strokeOffset = accumulatedOffset;
      accumulatedOffset -= strokeDash;

      circleSegments += `
        <circle
          cx="${size / 2}" cy="${size / 2}" r="${radius}"
          fill="transparent"
          stroke="${cat.color}"
          stroke-width="${strokeWidth}"
          stroke-dasharray="${strokeDash} ${circumference - strokeDash}"
          stroke-dashoffset="${strokeOffset}"
          stroke-linecap="round"
          class="transition-all duration-700 ease-out"
        />
      `;
    });

    const html = `
      <div class="flex items-center justify-between gap-3 min-w-0 overflow-hidden">
        <!-- SVG Donut -->
        <div class="relative flex-shrink-0" style="width: ${size}px; height: ${size}px;">
          <svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" class="transform -rotate-90">
            <!-- Background track -->
            <circle
              cx="${size / 2}" cy="${size / 2}" r="${radius}"
              fill="transparent"
              stroke="rgba(255, 255, 255, 0.06)"
              stroke-width="${strokeWidth}"
            />
            ${circleSegments}
          </svg>
          <!-- Center Text (Comfortably fits inside 102px inner circle) -->
          <div class="absolute inset-0 flex flex-col items-center justify-center text-center pointer-events-none px-2">
            <span class="text-[9px] font-bold text-slate-400 tracking-wider uppercase block leading-none mb-0.5">Total</span>
            <span class="text-xs font-black text-white tracking-tight tabular-nums block leading-tight truncate max-w-[90px]">${currency}${total.toLocaleString('en-IN')}</span>
            <span class="text-[8px] text-emerald-400 font-bold block leading-none mt-0.5">100% Tracked</span>
          </div>
        </div>

        <!-- Legend List (Guaranteed no overflow) -->
        <div class="flex-1 min-w-0 flex flex-col justify-center space-y-2">
          ${categories.map(cat => `
            <div class="flex items-center justify-between text-xs min-w-0">
              <div class="flex items-center gap-1.5 min-w-0 flex-1 mr-2">
                <span class="w-2 h-2 rounded-full flex-shrink-0" style="background-color: ${cat.color}; box-shadow: 0 0 6px ${cat.color}60;"></span>
                <span class="font-medium text-slate-300 truncate text-[11px] leading-tight" title="${cat.name}">${cat.name}</span>
              </div>
              <div class="text-right flex-shrink-0 flex items-baseline gap-1">
                <span class="font-bold text-white text-xs tabular-nums">${currency}${cat.current.toLocaleString('en-IN')}</span>
                <span class="text-[10px] text-slate-400 font-semibold tabular-nums">(${cat.percentage}%)</span>
              </div>
            </div>
          `).join('')}
        </div>
      </div>
    `;

    this.container.innerHTML = html;
  }
}
