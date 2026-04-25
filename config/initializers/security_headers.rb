Rails.application.config.session_store(
  :cookie_store,
  key: "_lubook_session",
  same_site: :lax,
  secure: Rails.env.production?
)

Rails.application.config.action_dispatch.default_headers.merge!(
  "X-Content-Type-Options" => "nosniff",
  "X-Frame-Options" => "DENY",
  "Referrer-Policy" => "strict-origin-when-cross-origin",
  "Permissions-Policy" => [
    "camera=()",
    "geolocation=()",
    "microphone=()",
    "payment=()",
    "usb=()"
  ].join(", ")
)
