// add a spinner to our navlinks when turbolinks:click is triggered
$(document).on('turbolinks:click', function(event){
  var $target = $(event.target);

  if ($target.is('#mainnav .nav-link')) {
    $target.append('<div class="flex-center nav-spinner"><div class="spinner-border text-primary" role="status"><span class="sr-only">Loading...</span></div></div>');
  }
});

// remove the spinner after the new page loads (or is being written to the cache)
$(document).on('turbolinks:load turbolinks:before-cache', function(){
  $('#mainnav .nav-spinner').remove();
});
