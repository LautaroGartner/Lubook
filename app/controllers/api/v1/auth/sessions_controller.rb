class Api::V1::Auth::SessionsController < ActionController::API
  include Api::V1::Serialization
  include ActionController::HttpAuthentication::Token::ControllerMethods

  def create
    user = User.find_for_authentication(email: params[:email].to_s.downcase)

    unless user&.valid_password?(params[:password].to_s)
      render json: { error: "Invalid email or password" }, status: :unauthorized
      return
    end

    unless user.confirmed?
      render json: { error: "Confirm your email before signing in" }, status: :forbidden
      return
    end

    token_record, raw_token = ApiToken.issue_for!(
      user: user,
      name: params[:device_name].presence || "iPhone"
    )

    render json: {
      token: raw_token,
      token_type: "Bearer",
      expires_at: token_record.expires_at&.iso8601,
      user: serialize_user(user, viewer: user)
    }, status: :created
  end

  def destroy
    raw_token = authenticate_with_http_token { |token, _options| token }
    digest = ApiToken.digest(raw_token)
    api_token = ApiToken.find_by(token_digest: digest)

    if api_token.present?
      api_token.destroy
      head :no_content
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
