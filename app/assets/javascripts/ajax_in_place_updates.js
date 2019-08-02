$(document).on('turbolinks:load', function(){
  $(document.body).on('ajax:send', function(event) {
    var $target = $(event.target);


    if ($target.hasClass('btn')) {
      $target.attr('disabled');
      $target.addClass('disabled');

      $target.html(
        '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Loading'
      );

    }
  });

  $(document.body).on('ajax:success', function(event) {
    var data = event.detail && event.detail[0];

    if (data && data.key && data.type && data.html) {
      $('[data-key="' + data.key + '"][data-type="' + data.type + '"]').replaceWith(data.html);
      $(document).trigger('ajax:loaded');
    }
  });
});
