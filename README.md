# MyLibrary

[![Build Status](https://github.com/sul-dlss/mylibrary/workflows/CI/badge.svg?branch=main)](https://github.com/sul-dlss/mylibrary/actions?query=workflow%3ACI+branch%3Amain)
[![Code Climate](https://codeclimate.com/github/sul-dlss/mylibrary/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/mylibrary)
[![Test Coverage](https://api.codeclimate.com/v1/badges/a8f1c5dab3a53ffba586/test_coverage)](https://codeclimate.com/github/sul-dlss/mylibrary/test_coverage)

MyLibrary is a patron facing application that displays library account information,
renews materials, cancels hold requests, makes payments of library fees and fines (via a hosted payment gateway),
and other features enhancing library user experience.

## Requirements

1. Ruby (3.1 or greater)
2. Bundler
3. Connection to Symphony Web Services (hosted on symws-prod.stanford.edu and symws-dev.stanford.edu)

## Installation

Clone the repository

    $ git clone https://github.com/sul-dlss/mylibrary.git

Change directories into the app and install dependencies

    $ bundle install
    $ yarn install

Start the development server

    $ bin/dev

## Configuring

The MyLibrary app will be configuired to connect to various backend web services, particularly Symphony Web Services and
ILLiad Web Services. This will likely happen on an environment to enviroment basis via `config/settings`, so that (e.g.) `development`
mode will point to `symws-dev` and `sul-illiad-test` respectively.

### Web Services Connectivity

For running the application in development mode you will need to connecting from a Stanford IP address (LAN, WiFi, or VPN)
in order to sucessfully make web services requests. Furthermore, ILLiad Web services requires an API key which will be
made available via a `shared_configs` file.

## Development

### Authentication

The application has two main modes of authentication:

- login by library id + pin
- login via shibboleth

Both logins require access to the symphony web services (see above) to retrieve a patron key. Logging in via shibboleth requires a properly configured Shibboleth environment with access to Stanford's LDAP attributes. In development, the shibboleth login can be faked by setting the `uid` environment variable when starting the rails server, e.g.:

```
$ uid=someuser rails s
```

Note, again, that the user must exist in symphony web services as well; this is only a bypass for the shibboleth authentication.

### Fixture users

Some integration tests use fixture users (stored in `spec/support/fixtures`) using some webmock magic to route
API requests to the appropriate fixture (see `spec/support/fake_symphony.rb`). These fixtures can be created
using the supplied rake task if you have the patron key:

```
$ rake fixtures:create[521183]
```

Note: these fixture objects are a snapshot of Symphony data frozen in time, and almost certainly do not reflect
the current data. This makes them useful for integration tests, but confusing to try to compare test output
with what you may see if you poke around the application in development.

Additional note: some fixture users have even been modified from their original form for ease of testing, perhaps
in ways that would be impossible to achieve by manipulating data in Symphony (e.g. `521181` has some fines, but
the patron standing is marked as 'OK' so we can reuse the patron for many different types of tests)

### Symphony Web Services API

This application uses the Symphony Web Services API to interact with the ILS. Documentation for this API is available
in the SDK and from the web services host (at e.g. `https://example.com/symws/sdk.html`). However, at this time,
the API does not provide all the information we need, so we use several other methods to get at patron information as well:

- the legacy web services API (used for retrieving payment history)
- direct Oracle Database access (used for differentiating the group sponsor's checkouts/requests/fines)

Note, too, that the API does not allow us to paginate within a list of checkouts/requests/fines, as they are retrieved as
part of the patron information request.

## A note about payments to Cybersource
Cybersource (a company owned by VISA) is our external payment processor for paying library fines. Cybersource offers several products; the one that we use is called "Secure Acceptance Hosted Checkout" because it is an externally-hosted system where the user goes to complete payment. The Cybersource website is frequently updated and links may break; the only reliable source of documentation about our particular product is the [Developer Guide PDF](https://developer.cybersource.com/library/documentation/dev_guides/Secure_Acceptance_Hosted_Checkout/Secure_Acceptance_Hosted_Checkout.pdf).

We currently support only one type of transaction: paying all of a user's payable fines together at once. When the user clicks the "pay all" button, we redirect their request to Cybersource via an interstitial form, which generates a POST request containing the data that sets up the checkout form along with a security signature. When the user completes their payment, Cybersource will POST some information back to us, including some of the information we originally sent which identifies the user and how much they paid. We pass this information to the ILS client to actually do the work of marking the fines as having been paid.

In Symphony, the ILS may take some time to actually reflect the payment, so we use a strategy involving setting a cookie based on the user's browser session to filter out fines that have been paid but not yet reflected in the ILS. Otherwise, the user might think that their payment didn't go through, because the fines are still showing. Those fines will be filtered (not shown on the fines page) for that current user's in browser session for 10 minutes. We are assuming a few things:

- That Symphony will resolve these transactions in at least 10 minutes
- That the user won't be switching browsers and expect their payments to be filtered to in flight payments

In FOLIO, the API request to mark a fine as paid is synchronous, so we don't need to worry about this.

## Testing

The test suite (with RuboCop style enforcement) will be run with the default rake task (also run on travis)

    $ rake

The specs can be run without RuboCop enforcement

    $ rake spec

The RuboCop style enforcement can be run without running the tests

    $ rake rubocop

## Deployment

Deployment of the application will be handled using the DLSS capistrano gem. To deploy the app to the development application
server run:

    $ cap dev deploy

## Feedback

You can provide feedback on MyLibrary through the "Feedback" link on the homepage. The [feedback queue](https://jirasul.stanford.edu/jira/projects/MYLIBACCNT) is managed in SUL JIRA.
