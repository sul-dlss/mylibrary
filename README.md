# MyLibrary
MyLibrary rails front-end application that uses Symphony Web Services to display library patron account information, 
allow renewal of materials, cancel hold requests, make payments of library fees and fines (via a hosted payment gateway),
and other features supported by Symphony Web Services API and other supported APIs to enhance library user experience and 
interactions with library access services.

## Requirements
1. Ruby (2.6.3 or greater)
2. Rails (5.2.3 or greater)
3. Connection to Symphony Web Services (hosted on symphony-webservices-prod.stanford.edu and
   symphony-webservices-dev.stanford.edu)

## Installation

Clone the repository

    $ git clone https://github.com/sul-dlss/mylibrary.git

Change directories into the app and install dependencies

    $ bundle install
    
Start the development server
    
    $ rails s
    
## Configuring

The MyLibrary app will be configuired to connect to various backend web services, particularly Symphony Web Services and
ILLiad Web Services. This will likely happen on an environment to enviroment basis via `config/settings`, so that (e.g.) `development`
mode will point to `symphony-webservices-dev` and `sul-illiad-test` respectively.

### Web Services Connectivity

For running the application in development mode you will need to connecting from a Stanford IP address (LAN, WiFi, or VPN)
in order to sucessfully make web services requests. Furthermore, ILLiad Web services requires an API key which will be 
made available via a `shared_configs` file.

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

Deployment of the production application will be handled via TravisCI 
