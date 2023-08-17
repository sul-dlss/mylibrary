// gtag intial setup
window.dataLayer = window.dataLayer || [];
function gtag(){dataLayer.push(arguments);}
gtag('js', new Date());

// Send event in required GA4 format to Google
function sendAnalyticsEvent({ action, category, label, value }) {
  window.gtag && window.gtag('event', action, {
    event_category: category,
    event_label: label,
    event_value: value
  });  
}

document.addEventListener('turbolinks:load', function() {
  // gtag set property and config
  const config = {}
  // To turn off analytics debug mode, exclude the parameter altogether (cannot just set to false)
  //See https://support.google.com/analytics/answer/7201382?hl=en#zippy=%2Cgoogle-tag-websites
  if (document.head.querySelector("meta[name=analytics_debug]").getAttribute('value') === "true") {
    config.debug_mode = true;
  }  
  gtag('config', 'G-XBQ5PKMBD4', config);

  document.querySelectorAll('.btn-renewable-submit').forEach(function(el) {
    el.addEventListener('click', function(e) {
      sendAnalyticsEvent({
        category: 'Renew',
        action: 'renew-single'
      })
    })
  })

  document.querySelectorAll('.btn-request-cancel').forEach(function(el) {
    el.addEventListener('click', function(e) {
      sendAnalyticsEvent({
        category: 'Request',
        action: 'cancel-single'
      })
    })
  })

  document.querySelectorAll('[href="/renewals/all_eligible"]').forEach(function(el) {
    el.addEventListener('click', function(e) {
      sendAnalyticsEvent({
        category: 'Renew',
        action: 'renew-all'
      })
    })
  })

  document.querySelectorAll('[data-target^="#collapseDetails"]').forEach(function(el) {
    el.addEventListener('click', function(e) {
      sendAnalyticsEvent({
        category: 'Toggle Details',
        action: e.currentTarget.classList.contains('collapsed') ? 'open' : 'close'
      })
    })
  });

  document.querySelectorAll('[href*="searchworks"]').forEach(function(el) {
    el.addEventListener('click', function(e) {
      sendAnalyticsEvent({
        category: 'View in SearchWorks',
        action: 'outbound click' 
      })
    })
  });

  document.querySelectorAll('[data-sort]').forEach(function(el) {
    el.addEventListener('click', function(e) {
      sendAnalyticsEvent({
        category: 'Sort',
        action: e.currentTarget.innerText
      })
    })
  });

  function contactFormSubmission(e) {
    var contactFormTo = $(e.currentTarget).closest('form').find('[data-contact-form-to-value]').text();
    sendAnalyticsEvent({
      category: 'Contact form',
      action: contactFormTo
    })
  }

  function changeRequestSubmission(e) {
    var originalDate = document.getElementById('#current_fill_by_date')?.value;
    var notNeededAfter = document.getElementById('#not_needed_after')?.value;

    var action = [];
    if (document.getElementById('#pickup_library').options.length > 0) {
      action.push('library');
    }
    if (originalDate && notNeededAfter && originalDate !== notNeededAfter) {
      action.push('date');
    }
    if (document.getElementById('#cancel')?.checked) {
      action.push('cancel');
    }

    sendAnalyticsEvent({
      category: 'Change Request',
      action: action.join(' ')
    })
  }

  document.querySelectorAll('[data-pay-button]').forEach(function(el) {
    el.addEventListener('click', function(e) {
      sendAnalyticsEvent({
        category: 'Pay fine',
        action: 'click to pay'
      })
    })
  });

  document.querySelectorAll('.alert-success').forEach(function(el) {
    if (el.innerText.includes('Payment may take up to 5 minutes to appear in your payment history')) {
      sendAnalyticsEvent({
        category: 'Pay fine',
        action: 'success'
      })
    }
  });

  document.querySelectorAll('.alert-danger').forEach(function(el) {
    if (el.innerText.includes('Payment canceled')) {
      sendAnalyticsEvent({
        category: 'Pay fine',
        action: 'canceled'
      })
    }
  });

  // Bootstrap 3 and 4 event detection depends on Jquery
  // Bootstrap 5 allows for native .addEventListener detection, but only if Jquery is not present at all
  // See https://getbootstrap.com/docs/5.0/getting-started/javascript/ heading "Jquery events"
  // Once this application is on Bootstrap 5, and Jquery is removed, we can change this Bootstrap event detection to pure JS
  $('#mylibrary-modal').on('shown.bs.modal', function(e) {
    document.querySelectorAll('form.contact-form button[type="submit"]').forEach(function(el) {
      el.addEventListener('click', contactFormSubmission)
    });
    document.querySelectorAll('.request-edit form button[type="submit"]').forEach(function(el) {
      el.addEventListener('click', changeRequestSubmission)
    });
  });
});
