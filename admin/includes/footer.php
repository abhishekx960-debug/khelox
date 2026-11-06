</main>
</div>

<div class="snackbar-host" id="snackHost" aria-live="polite" aria-atomic="true"></div>

<div class="modal fade" id="confirmModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered" style="max-width:420px">
        <div class="modal-content">
            <div class="modal-body p-4">
                <div class="d-flex align-items-start gap-3">
                    <span class="confirm-icon" id="confirmIcon"><i class="bi bi-exclamation-triangle"></i></span>
                    <div>
                        <h5 class="modal-title mb-1" id="confirmTitle">Confirm action</h5>
                        <p class="text-muted mb-0" id="confirmMsg">Are you sure you want to continue?</p>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-light" data-bs-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-danger" id="confirmOk">Confirm</button>
            </div>
        </div>
    </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script>
(function () {
  var progress = document.getElementById('pageProgress');
  var bar = progress ? progress.querySelector('.bar') : null;
  var host = document.getElementById('snackHost');
  var confirmEl = document.getElementById('confirmModal');
  var confirmModal = confirmEl ? new bootstrap.Modal(confirmEl) : null;
  var pendingForm = null;

  function setProgress(on, pct) {
    if (!progress || !bar) return;
    progress.classList.toggle('is-on', !!on);
    bar.style.width = (pct || 0) + '%';
  }
  window.addEventListener('load', function () {
    setProgress(true, 100);
    setTimeout(function () { setProgress(false, 0); }, 280);
  });
  document.querySelectorAll('a[href]:not([target="_blank"]):not([href^="#"]):not([href^="javascript"])').forEach(function (a) {
    a.addEventListener('click', function (e) {
      if (e.metaKey || e.ctrlKey || e.shiftKey || a.getAttribute('download') != null) return;
      var href = a.getAttribute('href') || '';
      if (!href || href.charAt(0) === '#') return;
      setProgress(true, 35);
      setTimeout(function () { setProgress(true, 70); }, 180);
    });
  });

  window.showSnack = function (type, msg) {
    if (!host || !msg) return;
    var map = { success: 'bi-check-lg', danger: 'bi-exclamation-circle', error: 'bi-exclamation-circle', warning: 'bi-exclamation-triangle', info: 'bi-info-circle', primary: 'bi-info-circle' };
    var el = document.createElement('div');
    el.className = 'snackbar ' + (type || 'info');
    el.innerHTML = '<span class="ic"><i class="bi ' + (map[type] || map.info) + '"></i></span><div class="msg"></div><button type="button" class="close" aria-label="Dismiss"><i class="bi bi-x-lg"></i></button>';
    el.querySelector('.msg').textContent = msg;
    host.appendChild(el);
    var hide = function () {
      el.classList.add('is-out');
      setTimeout(function () { el.remove(); }, 180);
    };
    el.querySelector('.close').addEventListener('click', hide);
    setTimeout(hide, 4200);
  };

  document.querySelectorAll('[data-flash-type]').forEach(function (n) {
    showSnack(n.getAttribute('data-flash-type'), n.getAttribute('data-flash-msg'));
  });

  document.querySelectorAll('form[data-confirm]').forEach(function (form) {
    form.addEventListener('submit', function (e) {
      if (form.dataset.confirmed === '1') { form.dataset.confirmed = '0'; return; }
      e.preventDefault();
      pendingForm = form;
      var danger = form.getAttribute('data-confirm-type') !== 'warn';
      document.getElementById('confirmTitle').textContent = form.getAttribute('data-confirm-title') || 'Confirm action';
      document.getElementById('confirmMsg').textContent = form.getAttribute('data-confirm') || 'Are you sure?';
      document.getElementById('confirmIcon').classList.toggle('is-warn', !danger);
      var ok = document.getElementById('confirmOk');
      ok.className = 'btn ' + (danger ? 'btn-danger' : 'btn-primary');
      ok.textContent = form.getAttribute('data-confirm-ok') || 'Confirm';
      confirmModal && confirmModal.show();
    });
  });
  var okBtn = document.getElementById('confirmOk');
  if (okBtn) {
    okBtn.addEventListener('click', function () {
      if (!pendingForm) return;
      pendingForm.dataset.confirmed = '1';
      confirmModal && confirmModal.hide();
      pendingForm.submit();
    });
  }

  document.querySelectorAll('form').forEach(function (form) {
    form.addEventListener('submit', function () {
      if (form.hasAttribute('data-confirm') && form.dataset.confirmed !== '1') return;
      var btn = form.querySelector('button[type="submit"],button:not([type])');
      if (!btn || btn.dataset.busy === '1') return;
      btn.dataset.busy = '1';
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
<?= $extraJs ?? '' ?>
</body>
</html>
