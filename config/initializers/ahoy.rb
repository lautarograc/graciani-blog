class Ahoy::Store < Ahoy::DatabaseStore
end

# Enable the JS API (mounted at /ahoy) so the browser can report custom
# events (scroll depth, time engaged) for the visit the server already
# started tracking.
Ahoy.api = true

# Resolve visit IP -> country/region/city via the geocoder gem (config/initializers/geocoder.rb).
Ahoy.geocode = true

# Anonymize the last octet of the IP before storing/geocoding it. Country-level
# lookups stay accurate; we just don't need to keep the full address around.
Ahoy.mask_ips = true

# Bots and crawlers are detected via the device_detector gem and are not
# recorded at all (default), so visitor counts in the dashboard are humans only.
# Ahoy.track_bots = false
