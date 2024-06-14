$(document).on('turbo:load', function(){
  $('[data-showpassword]').showPassword();
});


;(function ( $, window, document, undefined ) {
  /*
    jQuery plugin that handles password field hide/show

      Usage: $(selector).showPassword();

  */

  var pluginName = "showPassword";

  function Plugin( element, options ) {
      this.element = element;
      var $el, $target;

      this.options = $.extend( {}, options) ;
      this._name = pluginName;
      this.init();
  }

  Plugin.prototype = {
    init: function() {
      $el = $(this.element);
      $target = $('#' + $el.data().showpassword);
      this.ensureHidden();
      this.addOnClickHandlers();
      this.removeDisabled();
    },

    ensureHidden: function() {
      $el.find('[data-visibility-off]').hide();
    },

    addOnClickHandlers: function() {
      var $this = this;
      $el.find('[data-visibility]').on('click', function(e) {
        e.preventDefault();
        $target.attr('type', 'text');
        $(this).hide();
        $el.find('[data-visibility-off]').show();
      });
      $el.find('[data-visibility-off]').on('click', function(e) {
        e.preventDefault();
        $target.attr('type', 'password');
        $(this).hide();
        $el.find('[data-visibility]').show();
      });
    },

    removeDisabled: function() {
      $el.find('[disabled]').each(function() {
        $(this).removeAttr('disabled');
      });
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
