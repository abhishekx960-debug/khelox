</div>
    </section>
</div>
<div class="snackbar-host" id="snackHost" aria-live="polite" aria-atomic="true"></div>
<script>
(function () {
  var progress = document.getElementById('pageProgress');
  var bar = progress ? progress.querySelector('.bar') : null;
  var host = document.getElementById('snackHost');
  function setProgress(on, pct) {
    if (!progress || !bar) return;
    progress.classList.toggle('is-on', !!on);
    bar.style.width = (pct || 0) + '%';
  }
  window.addEventListener('load', function () {
    setProgress(true, 100);
    setTimeout(function () { setProgress(false, 0); }, 280);
  });
  window.showSnack = function (type, msg) {
    if (!host || !msg) return;
    var map = { success: 'bi-check-lg', danger: 'bi-exclamation-circle', error: 'bi-exclamation-circle', warning: 'bi-exclamation-triangle', info: 'bi-info-circle' };
    var el = document.createElement('div');
    el.className = 'snackbar ' + (type || 'info');
    el.innerHTML = '<span class="ic"><i class="bi ' + (map[type] || map.info) + '"></i></span><div class="msg"></div><button type="button" class="close" aria-label="Dismiss"><i class="bi bi-x-lg"></i></button>';
    el.querySelector('.msg').textContent = msg;
    host.appendChild(el);
    var hide = function () { el.classList.add('is-out'); setTimeout(function () { el.remove(); }, 180); };
    el.querySelector('.close').addEventListener('click', hide);
    setTimeout(hide, 4200);
  };
  document.querySelectorAll('[data-flash-type]').forEach(function (n) {
    showSnack(n.getAttribute('data-flash-type'), n.getAttribute('data-flash-msg'));
  });
  document.querySelectorAll('[data-toggle-pass]').forEach(function (b) {
    b.addEventListener('click', function () {
      var i = document.querySelector(b.dataset.togglePass);
      i.type = i.type === 'password' ? 'text' : 'password';
      b.querySelector('i').className = 'bi ' + (i.type === 'password' ? 'bi-eye' : 'bi-eye-slash');
    });
  });
  document.querySelectorAll('form').forEach(function (form) {
    form.addEventListener('submit', function () {
      var btn = form.querySelector('.auth-submit,button[type="submit"],button:not([type])');
      if (!btn || btn.disabled) return;
      btn.disabled = true;
      if (!btn.querySelector('.spin')) {
        var s = document.createElement('span');
        s.className = 'spin';
        btn.prepend(s);
      }
      setProgress(true, 55);
    });
  });
})();
</script>
</body>
</html>
