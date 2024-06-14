$(document).on('turbo:load', function(){
  $('[data-convert-button]').convertButton({
    classes: 'btn btn-link btn-icon-prefix'
  });
});


;(function ( $, window, document, undefined ) {
  /*
    jQuery plugin that converts anchor tags to buttons to be kinder to
    screenreader users but also preserve non-javascript browser interaction

      Usage: $(selector).convertButton();

  */

  var pluginName = "convertButton";

  function Plugin( element, options ) {
      this.element = element;
      var $el;

      this.options = $.extend( {}, options) ;
      this._name = pluginName;
      this.init();
  }

  Plugin.prototype = {
    init: function() {
      $el = $(this.element);
      var html = $el.html();
      var data = $el.data();
      // var events = $el._data('events')
      delete data['convertButton'];
      var newButton = $('<button/>', {
        class: this.options.classes,
        html: html
      });
      var attributes = $el.prop('attributes');
      $.each(attributes, function() {
        if (this.name === 'data-convert-button') {
          return true;
        }
        newButton.attr(this.name, this.value);
      });
      $el.replaceWith(newButton);
    },
  };

  // A really lightweight plugin wrapper around the constructor,
  // preventing against multiple instantiations
  $.fn[pluginName] = function ( options ) {
      return this.each(function () {
          if (!$.data(this, "plugin_" + pluginName)) {
              $.data(this, "plugin_" + pluginName,
              new Plugin( this, options ));
          }
      });
  };

})( jQuery, window, document );
