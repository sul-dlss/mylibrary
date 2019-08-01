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
});
