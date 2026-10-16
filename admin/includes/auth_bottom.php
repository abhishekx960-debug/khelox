</div>
    </section>
</div>
<script>
document.querySelectorAll('[data-toggle-pass]').forEach(function(b){
  b.addEventListener('click',function(){
    var i=document.querySelector(b.dataset.togglePass);
    i.type=i.type==='password'?'text':'password';
    b.querySelector('i').className='bi '+(i.type==='password'?'bi-eye':'bi-eye-slash');
  });
});
</script>
</body>
</html>