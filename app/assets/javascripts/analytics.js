GoogleAnalytics = (function() {
  function GoogleAnalytics() {}

  GoogleAnalytics.load = function() {
    GoogleAnalytics.analyticsId = GoogleAnalytics.getAnalyticsId();
    (function(i, s, o, g, r, a, m) {
      i['GoogleAnalyticsObject'] = r;
      i[r] = i[r] || function() {
        (i[r].q = i[r].q || []).push(arguments);
      };

      i[r].l = 1 * new Date;

      a = s.createElement(o);
      m = s.getElementsByTagName(o)[0];

      a.async = 1;
      a.src = g;
      m.parentNode.insertBefore(a, m);
    })(window, document, 'script', '//www.google-analytics.com/analytics.js', 'ga');
    ga('create', GoogleAnalytics.analyticsId, 'auto');
    ga('set', 'anonymizeIp', true);
  };

  GoogleAnalytics.trackPageview = function(url) {
    if (!GoogleAnalytics.isLocalRequest()) {
      return ga('send', {
          hitType: 'pageview',
          page: GoogleAnalytics.getPath()
        }
      );
    }
  };

  GoogleAnalytics.isLocalRequest = function() {
    return GoogleAnalytics.documentDomainIncludes('local');
  };

  GoogleAnalytics.documentDomainIncludes = function(str) {
    return document.domain.indexOf(str) !== -1;
  };

  GoogleAnalytics.getAnalyticsId = function() {
    return $('[data-analytics-id]').data('analytics-id');
  };

  // Remove the protocol and the host and only return the path with any params
  GoogleAnalytics.getPath = function() {
    return location.href
             .replace(location.protocol + '//' + location.host, '');
  };

  return GoogleAnalytics;

})();

$(document).on('turbolinks:load', function(){
  GoogleAnalytics.load();
  if (GoogleAnalytics.analyticsId){
    GoogleAnalytics.trackPageview();
  }

  $('.btn-renewable-submit').on('click', function(e) {
    ga('send', 'event', {
      eventCategory: 'Renew',
      eventAction: 'renew-single',
      transport: 'beacon'
    });
  });

  $('.btn-request-cancel').on('click', function(e) {
    ga('send', 'event', {
      eventCategory: 'Request',
      eventAction: 'cancel-single',
      transport: 'beacon'
    });
  });

  $('[href="/renewals/all_eligible"]').on('click', function(e) {
    ga('send', 'event', {
      eventCategory: 'Renew',
      eventAction: 'renew-all',
      transport: 'beacon'
    });
  });

  $('[data-target^="#collapseDetails"]').on('click', function(e) {
    var collapsed = $(e.currentTarget).hasClass('collapsed');
    ga('send', 'event', {
      eventCategory: 'Toggle Details',
      eventAction: collapsed ? 'open' : 'close',
      transport: 'beacon'
    });
  });

  $('[href^="https://searchworks.stanford.edu"]').on('click', function(e) {
    ga('send', 'event', {
      eventCategory: 'View in SearchWorks',
      transport: 'beacon'
    });
  });

  $('[data-sort]').on('click', function(e) {
    ga('send', 'event', {
      eventCategory: 'Sort',
      eventAction: e.currentTarget.innerText,
      transport: 'beacon'
    });
  });

  function contactFormSubmission(e) {
    var contactFormTo = $(e.currentTarget).closest('form').find('[data-contact-form-to-value]').text();
    ga('send', 'event', {
      eventCategory: 'Contact form',
      eventAction: contactFormTo,
      transport: 'beacon'
    });
  }

  function changeRequestSubmission(e) {
    var changeForm = $(e.currentTarget).closest('form');
    var originalDate = changeForm.find('#current_fill_by_date').val();
    var notNeededAfter = changeForm.find('#not_needed_after').val();

    var action = [];
    if (changeForm.find('#pickup_library').val().length > 0) {
      action.push('library');
    }
    if (originalDate !== notNeededAfter) {
      action.push('date');
    }
    if (changeForm.find('#cancel').prop('checked')) {
      action.push('cancel');
    }
    ga('send', 'event', {
      eventCategory: 'Change Request',
      eventAction: action.join(' '),
      transport: 'beacon'
    });
  }

  $('form.contact-form button[type="submit"]').on('click', contactFormSubmission);
  $('.request-edit form button[type="submit"]').on('click', changeRequestSubmission);

  $('[data-pay-button]').on('click', function(e) {
    ga('send', 'event', {
      eventCategory: 'Pay fine',
      eventAction: 'click to pay',
      transport: 'beacon'
    });
  });

  $('body .alert-success:contains("Payment may take up to 5 minutes to appear in your payment history")').each(function(i, val) {
    ga('send', 'event', {
      eventCategory: 'Pay fine',
      eventAction: 'success',
      transport: 'beacon'
    });
  });

  $('body .alert-danger:contains("Payment canceled")').each(function(i, val) {
    ga('send', 'event', {
      eventCategory: 'Pay fine',
      eventAction: 'canceled',
      transport: 'beacon'
    });
  });


  // Things that may happen in a modal
  $('#mylibrary-modal').on('shown.bs.modal', function(e) {
    $('form.contact-form button[type="submit"]').on('click', contactFormSubmission);
    $('.request-edit form button[type="submit"]').on('click', changeRequestSubmission);
  });

});
