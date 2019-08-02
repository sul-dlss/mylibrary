$(document).on('turbolinks:load', function(){
  $(document.body).on('ajax:success', function(event) {
    var data = event.detail && event.detail[0];

    if (data && data.key && data.type && data.html) {
      $('[data-key="' + data.key + '"][data-type="' + data.type + '"]').replaceWith(data.html);
      $(document).trigger('ajax:loaded');
    }
  });
});
