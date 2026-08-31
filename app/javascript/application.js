// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

import "lexxy"

import "ahoy"
// The server already starts the visit on first request; skip ahoy.js's own
// redundant POST to /ahoy/visits and just use it for event tracking + tokens.
ahoy.configure({ trackVisits: false })
