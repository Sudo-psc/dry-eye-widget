/* Dry Eye Widget landing — interactions: theme, lang, carousel, ring timer, reveal */
(function () {
  /* ---------- Theme ---------- */
  function setTheme(t) {
    document.documentElement.setAttribute("data-theme", t);
    try { localStorage.setItem("dew-theme", t); } catch (e) {}
  }
  window.dewSetTheme = setTheme;
  function initTheme() {
    let t = null;
    try { t = localStorage.getItem("dew-theme"); } catch (e) {}
    if (!t) t = window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    document.documentElement.setAttribute("data-theme", t);
  }
  initTheme();

  /* ---------- Demo video (lazy) ----------
     Não há <source> no HTML e não há autoplay: o poster basta no LCP.
     Carrega o MP4 só quando o bloco entra na viewport (ou no play).
     Em mobile / save-data / 2G usa a versão comprimida (~460 KB vs ~2,3 MB). */
  function resolveDemoSrc(v) {
    var conn = navigator.connection || {};
    var lite = window.matchMedia("(max-width: 640px)").matches ||
      conn.saveData === true ||
      /(^|-)2g$/.test(conn.effectiveType || "");
    var mobile = v.getAttribute("data-src-mobile");
    var full = v.getAttribute("data-src");
    return lite && mobile ? mobile : full;
  }

  function attachDemoSource(v) {
    if (!v || v.getAttribute("data-loaded") === "1") return;
    var want = resolveDemoSrc(v);
    if (!want) return;
    var srcEl = v.querySelector("source");
    if (!srcEl) {
      srcEl = document.createElement("source");
      srcEl.type = "video/mp4";
      v.appendChild(srcEl);
    }
    if (srcEl.getAttribute("src") !== want) {
      srcEl.setAttribute("src", want);
      v.load();
    }
    v.setAttribute("data-loaded", "1");
  }

  function setupDemoVideo() {
    var v = document.getElementById("demo-video");
    if (!v) return;
    // Usuário pediu play antes do observer: carrega na hora.
    v.addEventListener("play", function () { attachDemoSource(v); }, { once: true });
    if ("IntersectionObserver" in window) {
      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) {
            attachDemoSource(v);
            io.disconnect();
          }
        });
      }, { rootMargin: "200px 0px" });
      io.observe(v);
    } else {
      // Fallback antigo: carrega no idle / timeout curto.
      var run = function () { attachDemoSource(v); };
      if (window.requestIdleCallback) window.requestIdleCallback(run, { timeout: 2500 });
      else setTimeout(run, 1200);
    }
  }

  document.addEventListener("DOMContentLoaded", function () {
    if (typeof window.dewInitLang === "function") window.dewInitLang();
    setupDemoVideo();

    const themeBtn = document.getElementById("theme-toggle");
    if (themeBtn) themeBtn.addEventListener("click", function () {
      const cur = document.documentElement.getAttribute("data-theme");
      setTheme(cur === "dark" ? "light" : "dark");
    });

    document.querySelectorAll(".lang-switch button").forEach(function (b) {
      b.addEventListener("click", function () {
        if (typeof window.dewSetLang === "function") window.dewSetLang(b.dataset.lang);
      });
    });

    /* ---------- Hero ring countdown (20 s loop) ---------- */
    const ring = document.getElementById("ring-fill");
    const timerEl = document.getElementById("demo-timer");
    const chipEl = document.getElementById("chip-timer");
    if (ring && timerEl) {
      const C = 2 * Math.PI * 78; // r=78
      ring.setAttribute("stroke-dasharray", String(C));
      let s = 20;
      const reduced = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
      function tick() {
        timerEl.textContent = "00:" + String(s).padStart(2, "0");
        ring.setAttribute("stroke-dashoffset", String(C * (1 - s / 20)));
        if (chipEl) {
          const m = 19 - Math.floor((20 - s) / 3) % 20;
          chipEl.textContent = String(Math.max(m, 1)).padStart(2, "0") + ":42";
        }
        s = s <= 0 ? 20 : s - 1;
      }
      tick();
      if (!reduced) setInterval(tick, 1000);
    }

    /* ---------- Carousel + platform filter ---------- */
    const track = document.getElementById("shots-track");
    if (track) {
      const dotsBox = document.getElementById("shots-dots");
      let cur = 0;
      let platform = "all";

      function visibleSlides() {
        return Array.from(track.children).filter(function (s) {
          if (s.hidden) return false;
          if (platform === "all") return true;
          return s.getAttribute("data-platform") === platform;
        });
      }

      function rebuildDots() {
        if (!dotsBox) return;
        dotsBox.innerHTML = "";
        visibleSlides().forEach(function (_, i) {
          const d = document.createElement("button");
          d.type = "button";
          d.setAttribute("aria-label", "Slide " + (i + 1));
          d.addEventListener("click", function () { goTo(i); });
          dotsBox.appendChild(d);
        });
        syncDots();
      }

      function applyPlatform(next) {
        platform = next;
        Array.from(track.children).forEach(function (s) {
          const p = s.getAttribute("data-platform") || "macos";
          s.hidden = platform !== "all" && p !== platform;
        });
        const plat = document.getElementById("shots-platform");
        if (plat) {
          plat.querySelectorAll("button[data-platform]").forEach(function (btn) {
            btn.setAttribute("aria-pressed", String(btn.getAttribute("data-platform") === platform));
          });
        }
        rebuildDots();
        goTo(0);
      }

      function goTo(i) {
        const slides = visibleSlides();
        if (!slides.length) return;
        cur = Math.max(0, Math.min(slides.length - 1, i));
        const s = slides[cur];
        track.scrollTo({ left: s.offsetLeft - (track.clientWidth - s.clientWidth) / 2, behavior: "smooth" });
        syncDots();
      }

      function syncDots() {
        if (!dotsBox) return;
        const slides = visibleSlides();
        const dots = Array.from(dotsBox.children);
        if (!slides.length) return;
        const center = track.scrollLeft + track.clientWidth / 2;
        let best = 0, bestD = Infinity;
        slides.forEach(function (s, i) {
          const d = Math.abs(s.offsetLeft + s.clientWidth / 2 - center);
          if (d < bestD) { bestD = d; best = i; }
        });
        cur = best;
        dots.forEach(function (d, i) { d.setAttribute("aria-current", String(i === cur)); });
      }

      track.addEventListener("scroll", function () { requestAnimationFrame(syncDots); }, { passive: true });
      const prev = document.getElementById("shots-prev");
      const next = document.getElementById("shots-next");
      if (prev) prev.addEventListener("click", function () { goTo(cur - 1); });
      if (next) next.addEventListener("click", function () { goTo(cur + 1); });

      const plat = document.getElementById("shots-platform");
      if (plat) {
        plat.addEventListener("click", function (e) {
          const btn = e.target.closest("button[data-platform]");
          if (!btn) return;
          applyPlatform(btn.getAttribute("data-platform"));
        });
      }
      rebuildDots();
    }

    /* ---------- Reveal on scroll ----------
       Fail-safe: elementos são visíveis por padrão (CSS não os esconde).
       O fade-in é todo aplicado via JS inline e SEMPRE termina com a
       limpeza dos estilos (setTimeout), garantindo visibilidade mesmo
       se transições CSS não progredirem (ex.: iframes de preview). */
    const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
    function animateReveal(el) {
      if (reducedMotion) return;
      el.style.opacity = "0";
      el.style.transform = "translateY(18px)";
      el.style.transition = "opacity 600ms ease, transform 600ms ease";
      setTimeout(function () {
        el.style.opacity = "1";
        el.style.transform = "none";
      }, 30);
      setTimeout(function () {
        el.style.transition = "none";
        el.style.opacity = "";
        el.style.transform = "";
        setTimeout(function () { el.style.transition = ""; }, 60);
      }, 700);
    }
    let pending = Array.from(document.querySelectorAll(".reveal"));
    function checkReveals() {
      if (!pending.length) return;
      const vh = window.innerHeight;
      pending = pending.filter(function (el) {
        const r = el.getBoundingClientRect();
        if (r.top < vh * 0.92 && r.bottom > 0) { el.classList.add("in"); animateReveal(el); return false; }
        return true;
      });
    }
    checkReveals();
    window.addEventListener("scroll", checkReveals, { passive: true });
    window.addEventListener("resize", checkReveals, { passive: true });
    const revealPoll = setInterval(function () {
      checkReveals();
      if (!pending.length) clearInterval(revealPoll);
    }, 280);
  });
})();
