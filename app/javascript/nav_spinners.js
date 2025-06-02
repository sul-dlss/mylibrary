// add a spinner to our navlinks when turbo:click is triggered
$(document).on('turbo:click', function(event){
  var $target = $(event.target);

  if ($target.is('#mainnav .nav-link')) {
    $target.append('<div class="flex-center nav-spinner"><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading...</span></div></div>');
  }
});

// remove the spinner after the new page loads (or is being written to the cache)
$(document).on('turbo:load turbo:before-cache', function(){
  $('#mainnav .nav-spinner').remove();
});
