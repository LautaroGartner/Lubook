Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data, "https://fonts.gstatic.com"
    policy.img_src     :self, :data, :blob, :https
    policy.object_src  :none
    policy.script_src  :self
    policy.style_src   :self, "https://fonts.googleapis.com"
    policy.connect_src :self
    policy.frame_ancestors :none
    policy.base_uri    :self
    policy.form_action :self
  end

  config.content_security_policy_nonce_generator = ->(request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]

  config.content_security_policy_report_only = Rails.env.development?
end
