var options = {
    valueNames: [
      'status',
      'title',
      'author',
      { name: 'call_number', attr: 'data-shelfkey' },
      { name: 'due_date', attr: 'data-date' },
    ],
};

$(document).on('turbolinks:load', function(){
  // var checkouts = new List('checkouts', options);
  $('#checkouts').listSort(options);
});


;(function ( $, window, document, undefined ) {
  /*
    jQuery plugin that handles some sort functionality

      Usage: $(selector).sortThingy();

    No available options

    This plugin :
      - does sorty stuff
  */

    var pluginName = 'listSort';

    function Plugin( element, options ) {
        this.element = element;
        this.options = $.extend( {}, options) ;

        this._name = pluginName;
        this.checkouts = new List(element, options);
        this.state = { sort: $(element).data('sort') };

        this.init();
    }

    Plugin.prototype = {
      init: function() {
        this.addOnClickHandlers();
      },

      addOnClickHandlers: function() {
        var $this = this;

        this._sortTriggers().on('click', function(e) {
          $this.setState({ sort: $(e.currentTarget).data('sort') });
        });
      },

      setState: function(newState) {
        var stateChanged = this.state.sort !== newState.sort;
        if (!stateChanged) return;

        this.state = newState;
        this.render();
      },

      render: function() {
        var sort = this.state.sort;

        // a) trigger list sort function
        this.checkouts.sort(sort);

        // b) rerender the dropdown label
        var filteredSortTriggers = this._sortTriggers().filter('[data-sort="' + sort + '"]');
        var sortLabelValue = filteredSortTriggers.first().text();
        this._sortLabel().html(sortLabelValue);

        // c) add active classes to the column header thingy
        this._sortTriggers().removeClass('active');
        filteredSortTriggers.addClass('active');
      },

      _sortTriggers: function() {
        return $(this.element).find('[data-sort]');
      },

      _sortLabel: function() {
        return $(this.element).find('[data-sort-label]');
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
