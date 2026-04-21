class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include Pagy::Backend

  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_social_counts, if: :user_signed_in?
  before_action :track_last_active!, if: :user_signed_in?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :username ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :username, :share_last_seen, :share_read_receipts ])
  end

  def user_not_authorized
    flash[:alert] = "You're not authorized to do that."
    redirect_back(fallback_location: root_path)
  end

  def set_social_counts
    @unread_notifications_count = current_user.unread_notifications_count
    @unread_chats_count = current_user.unread_chats_count
  end

  def track_last_active!
    last_ping = session[:last_active_ping_at].presence && Time.at(session[:last_active_ping_at].to_i)
    return if last_ping.present? && last_ping >= 1.minute.ago

    current_user.update_column(:last_active_at, Time.current)
    session[:last_active_ping_at] = Time.current.to_i
  end

  def after_sign_in_path_for(_resource)
    root_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end
end
