// Entry point for the build script in your package.json

import './jquery-shim'

import Rails from 'rails-ujs'

import * as bootstrap from "bootstrap"
import './ajax_in_place_updates'
import './analytics'
import './contact_form'
import './convertButton'
import './listSort'
import './modal'
import './nav_spinners'
import './showPassword'
import './toggleClassWithExpand'

Rails.start()
import "@hotwired/turbo-rails"
