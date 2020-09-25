$(document).on('turbolinks:load ajax:loaded', function(){

  $('[data-cdl-waitlist] a').on('click', function() {
    var container = $(this);
    container.html('')
    container.addClass('spinner-border spinner-border-sm')
  });
});
