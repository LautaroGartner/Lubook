class Api::V1::BaseController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  before_action :authenticate_api_user!

  attr_reader :current_api_token, :current_api_user

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def authenticate_api_user!
    raw_token = bearer_token
    digest = ApiToken.digest(raw_token)

    @current_api_token = ApiToken.includes(:user).active.find_by(token_digest: digest)
    @current_api_user = @current_api_token&.user

    if @current_api_token.blank? || @current_api_token.expired?
      render_unauthorized("Unauthorized")
      return
    end

    @current_api_token.update_column(:last_used_at, Time.current)
  end

  def bearer_token
    authenticate_with_http_token do |token, _options|
      return token
    end

    nil
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end

  def render_not_found
    render json: { error: "Not found" }, status: :not_found
  end
end
