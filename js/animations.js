// Animation Engine: Rapid Ticker, Glow Flares, Confetti & Audio/Haptics
class AnimationEngine {
  constructor() {
    this.audioCtx = null;
    this.initConfettiCanvas();
  }

  // Audio synthesizer for Apple Pay / iOS Cash style chime
  getAudioContext() {
    if (!this.audioCtx && (window.AudioContext || window.webkitAudioContext)) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      this.audioCtx = new AudioCtx();
    }
    if (this.audioCtx && this.audioCtx.state === 'suspended') {
      this.audioCtx.resume();
    }
    return this.audioCtx;
  }

  playCashChime() {
    try {
      const ctx = this.getAudioContext();
      if (!ctx) return;

      const now = ctx.currentTime;
      // High-pitched pleasant dual harmonic chime (880Hz + 1320Hz)
      const osc1 = ctx.createOscillator();
      const osc2 = ctx.createOscillator();
      const gainNode = ctx.createGain();

      osc1.type = 'sine';
      osc2.type = 'triangle';

      osc1.frequency.setValueAtTime(880, now); // A5
      osc1.frequency.exponentialRampToValueAtTime(1760, now + 0.12); // A6

      osc2.frequency.setValueAtTime(1320, now); // E6
      osc2.frequency.exponentialRampToValueAtTime(2640, now + 0.14);

      gainNode.gain.setValueAtTime(0.18, now);
      gainNode.gain.exponentialRampToValueAtTime(0.001, now + 0.35);

      osc1.connect(gainNode);
      osc2.connect(gainNode);
      gainNode.connect(ctx.destination);

      osc1.start(now);
      osc2.start(now);
      osc1.stop(now + 0.35);
      osc2.stop(now + 0.35);
    } catch (e) {
      // Audio might be blocked until user gesture, graceful fallback
    }
  }

  // Tactile Haptic feedback
  haptic(pattern = [15]) {
    if ('vibrate' in navigator) {
      try {
        navigator.vibrate(pattern);
      } catch (e) {}
    }
  }

  // Smooth Ease-Out Quintic Function for rapid deceleration
  easeOutQuint(x) {
    return 1 - Math.pow(1 - x, 5);
  }

  // Rapid Number Counter Roll-up (INR • ₹ Optimized)
  animateNumber(element, startVal, endVal, duration = 850, prefix = '₹', suffix = '') {
    if (!element) return;
    const start = parseFloat(startVal) || 0;
    const end = parseFloat(endVal) || 0;

    if (start === end) {
      element.textContent = `${prefix}${Math.round(end).toLocaleString('en-IN')}${suffix}`;
      return;
    }

    element.classList.add('rapid-number-active');
    const startTime = performance.now();

    const update = (currentTime) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const easedProgress = this.easeOutQuint(progress);
      const current = start + (end - start) * easedProgress;

      element.textContent = `${prefix}${Math.round(current).toLocaleString('en-IN')}${suffix}`;

      if (progress < 1) {
        requestAnimationFrame(update);
      } else {
        element.textContent = `${prefix}${Math.round(end).toLocaleString('en-IN')}${suffix}`;
        setTimeout(() => {
          element.classList.remove('rapid-number-active');
        }, 150);
      }
    };

    requestAnimationFrame(update);
  }

  // Rapid Flash Highlight on Card
  flashCard(cardElement, variant = 'emerald') {
    if (!cardElement) return;

    cardElement.classList.remove('card-flash-emerald', 'card-flash-blue', 'card-flash-purple');
    void cardElement.offsetWidth; // Trigger reflow
    cardElement.classList.add(`card-flash-${variant}`);

    // Create subtle floating "+$X" ripple or spark badge if needed
    setTimeout(() => {
      cardElement.classList.remove(`card-flash-${variant}`);
    }, 1100);
  }

  // Button Click Bounce Animation
  popButton(buttonElement) {
    if (!buttonElement) return;
    this.haptic([10]);
    buttonElement.classList.remove('btn-bounce-active');
    void buttonElement.offsetWidth;
    buttonElement.classList.add('btn-bounce-active');
    setTimeout(() => {
      buttonElement.classList.remove('btn-bounce-active');
    }, 300);
  }

  // Full-screen Canvas Confetti Particle System
  initConfettiCanvas() {
    this.canvas = document.createElement('canvas');
    this.canvas.id = 'confetti-canvas';
    this.canvas.style.cssText = `
      position: fixed;
      inset: 0;
      width: 100vw;
      height: 100vh;
      pointer-events: none;
      z-index: 9999;
    `;
    document.body.appendChild(this.canvas);
    this.ctx = this.canvas.getContext('2d');
    this.particles = [];
    this.animating = false;

    window.addEventListener('resize', () => {
      if (this.canvas) {
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
      }
    });
    this.canvas.width = window.innerWidth;
    this.canvas.height = window.innerHeight;
  }

  triggerConfetti(x = window.innerWidth / 2, y = window.innerHeight / 3, count = 45) {
    if (!this.canvas) this.initConfettiCanvas();
    const colors = ['#10b981', '#34d399', '#06b6d4', '#60a5fa', '#f59e0b', '#ec4899', '#a855f7'];

    for (let i = 0; i < count; i++) {
      const angle = (Math.PI * 2 * i) / count + (Math.random() - 0.5) * 0.5;
      const speed = 4 + Math.random() * 8;
      this.particles.push({
        x: x,
        y: y,
        vx: Math.cos(angle) * speed,
        vy: Math.sin(angle) * speed - 3,
        size: 5 + Math.random() * 6,
        color: colors[Math.floor(Math.random() * colors.length)],
        rotation: Math.random() * 360,
        rotationSpeed: (Math.random() - 0.5) * 12,
        alpha: 1,
        decay: 0.015 + Math.random() * 0.015,
        shape: Math.random() > 0.4 ? 'rect' : 'circle'
      });
    }

    if (!this.animating) {
      this.animating = true;
      this.renderConfetti();
    }
  }

  renderConfetti() {
    if (!this.ctx) return;
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);

    for (let i = this.particles.length - 1; i >= 0; i--) {
      const p = this.particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.vy += 0.25; // gravity
      p.vx *= 0.98; // air friction
      p.rotation += p.rotationSpeed;
      p.alpha -= p.decay;

      if (p.alpha <= 0 || p.y > this.canvas.height) {
        this.particles.splice(i, 1);
        continue;
      }

      this.ctx.save();
      this.ctx.globalAlpha = p.alpha;
      this.ctx.fillStyle = p.color;
      this.ctx.translate(p.x, p.y);
      this.ctx.rotate((p.rotation * Math.PI) / 180);

      if (p.shape === 'rect') {
        this.ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size * 0.6);
      } else {
        this.ctx.beginPath();
        this.ctx.arc(0, 0, p.size / 2, 0, Math.PI * 2);
        this.ctx.fill();
      }
      this.ctx.restore();
    }

    if (this.particles.length > 0) {
      requestAnimationFrame(() => this.renderConfetti());
    } else {
      this.animating = false;
      this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    }
  }
}

const animEngine = new AnimationEngine();
