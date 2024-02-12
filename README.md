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

The MyLibrary app will be configuired to connect to various backend web services, particularly FOLIO and
ILLiad Web Services. This will likely happen on an environment to enviroment basis via `config/settings`, so that (e.g.) `development` mode will point to `okapi-test` for FOLIO endpoints, `sul-folio-graphql-test` for our custom graphql interface to FOLIO, and `sul-illiad-test`.

### Web Services Connectivity

For running the application in development mode you will need to connecting from a Stanford IP address (LAN, WiFi, or VPN)
in order to sucessfully make web services requests. Furthermore, ILLiad Web services requires an API key which will be
made available via a `shared_configs` file.

## Development

### Authentication

The application has two main modes of authentication:

- login by library id + pin
- login via shibboleth

Both logins require access to the FOLIO web services (see above) to retrieve a patron key. Logging in via shibboleth requires a properly configured Shibboleth environment with access to Stanford's LDAP attributes. In development, the shibboleth login can be faked by setting the `uid` environment variable when starting the rails server, e.g.:

```
$ uid=someuser rails s
```

Note, again, that the user must exist in FOLIO as well; this is only a bypass for the shibboleth authentication.


### FOLIO data

This application interacts with the FOLIO ILS. Our `FolioClient` class hits the FOLIO Okapi API gateway located at `folio.url` in the settings file. `FolioClient` also delegates some requests to our `FolioGraphqlClient`, which hits a custom endpoint specified at `folio_graphql.url` in settings. Some data required for this application, such as patron info, is better served by our custom API than Okapi because we are able to design the responses. You can find our repository for the graphql API at [https://github.com/sul-dlss/folio-graphql](https://github.com/sul-dlss/folio-graphql).

## A note about payments to Cybersource
Cybersource (a company owned by VISA) is our external payment processor for paying library fines. Cybersource offers several products; the one that we use is called "Secure Acceptance Hosted Checkout" because it is an externally-hosted system where the user goes to complete payment. The Cybersource website is frequently updated and links may break; the only reliable source of documentation about our particular product is the [Developer Guide PDF](https://developer.cybersource.com/library/documentation/dev_guides/Secure_Acceptance_Hosted_Checkout/Secure_Acceptance_Hosted_Checkout.pdf).

We currently support only one type of transaction: paying all of a user's payable fines together at once. When the user clicks the "pay all" button, we redirect their request to Cybersource via an interstitial form, which generates a POST request containing the data that sets up the checkout form along with a security signature. When the user completes their payment, Cybersource will POST some information back to us, including some of the information we originally sent which identifies the user and how much they paid. We pass this information to the ILS client to actually do the work of marking the fines as having been paid.

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
