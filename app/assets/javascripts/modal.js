// Adapted from https://github.com/projectblacklight/blacklight/blob/master/app/javascript/blacklight/modal.js

Mylibrary = {};

if (Mylibrary.modal === undefined) {
  Mylibrary.modal = {};
}

Mylibrary.modal.modalSelector = '#mylibrary-modal';
Mylibrary.modal.containerSelector    = '[data-mylibrary-modal~=container]';
Mylibrary.modal.modalCloseSelector   = '[data-mylibrary-modal~=close]';

Mylibrary.modal.modalAjaxClickLink = function(e) {
  e.preventDefault();
  
  $.ajax({
    url: $(this).attr('href')
  })
  .fail(Mylibrary.modal.onFailure)
  .done(Mylibrary.modal.receiveAjax)
}

// Called on fatal failure of ajax load, function returns content
// to show to user in modal.  Right now called only for extreme
// network errors.
Mylibrary.modal.onFailure = function(data) {
  var contents =  '<div class="modal-header">' +
            '<div class="modal-title">Network Error</div>' +
            '<button type="button" class="mylibrary-modal-close close" data-dismiss="modal" aria-label="Close">' +
            '  <span aria-hidden="true">&times;</span>' +
            '</button>';
  $(Mylibrary.modal.modalSelector).find('.modal-content').html(contents);
  $(Mylibrary.modal.modalSelector).modal('show');
}

Mylibrary.modal.receiveAjax = function (contents) {
  // does it have a data- selector for container?
  // important we don't execute script tags, we shouldn't.
  // code modelled off of JQuery ajax.load. https://github.com/jquery/jquery/blob/master/src/ajax/load.js?source=c#L62
  var container =  $('<div>').
    append( jQuery.parseHTML(contents) ).find( Mylibrary.modal.containerSelector ).first();
  if (container.length !== 0) {
    contents = container.html();
  }

  $(Mylibrary.modal.modalSelector).find('.modal-content').html(contents);

  // send custom event with the modal dialog div as the target
  var e    = $.Event('loaded.mylibrary.mylibrary-modal')
  $(Mylibrary.modal.modalSelector).trigger(e);
  // if they did preventDefault, don't show the dialog
  if (e.isDefaultPrevented()) return;

  $(Mylibrary.modal.modalSelector).modal('show');
};

$(document).on('turbolinks:load', function(){
  $('body').on('click', 'a[data-mylibrary-modal~=trigger]', Mylibrary.modal.modalAjaxClickLink);
});
