Geocoder.configure(
  ip_lookup: :ipapi_com, # ip-api.com's free tier: no key, no signup, ~45 req/min
  # cache repeated lookups (same visitor IP across multiple visits) in Rails.cache
  # instead of an unbounded in-memory hash
  cache: Rails.cache,
  cache_prefix: "geocoder:"
)
