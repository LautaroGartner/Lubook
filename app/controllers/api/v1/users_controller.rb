class Api::V1::UsersController < Api::V1::BaseController
  include Api::V1::Serialization

  def show
    render json: { user: serialize_user(current_api_user, viewer: current_api_user) }
  end
end
