$(document).on('turbolinks:load', function(){
  $('.list-group-item .collapse').toggleClassWithExpand();
});

;(function ( $, window, document, undefined ) {
  /*
    jQuery plugin that handles adding classes to parent elements of Bootstrap collapse elements

      Usage: $(selector).toggleClassWithExpand();

    Options
      parentSelector: a selector that will be used to find the parent to apply the class to.  (default: '.list-group-item')
      expandedClass: the class to apply/remove on the parent when the collapsible element is expanded (default: 'expanded')

    This plugin :
      - Adds a configurable class onto a configurable parent so that it can be styled
        when an internal bootstrap collapsible element is expanded or collapsed
  */

    var pluginName = 'toggleClassWithExpand';

    function Plugin( element, options ) {
        this.element = element;
        this.options = $.extend( {
          expandedClass: 'expanded',
          parentSelector: '.list-group-item'
        }, options) ;

        this._name = pluginName;
        this.init();
    }

    Plugin.prototype = {
      init: function() {
        var _this = this;
        var $collapse = $(_this.element);

        $collapse.on('show.bs.collapse', function() {
          $(this).parent(_this.options.parentSelector).addClass(_this.options.expandedClass);
        });

        $collapse.on('hide.bs.collapse', function() {
          $(this).parent(_this.options.parentSelector).removeClass(_this.options.expandedClass);
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
