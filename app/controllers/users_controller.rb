class UsersController < ApplicationController
  def index
    @users = User.includes(:profile)
                 .where.not(id: current_user.id)
                 .order(:username)

    # Preload the current user's outgoing follows to check status efficiently
    @outgoing_follows = current_user.sent_follow_requests.index_by(&:receiver_id)
  end

  def show
    @user = User.includes(:profile).find(params[:id])
    @follow = current_user.sent_follow_requests.find_by(receiver_id: @user.id)
    @is_self = @user.id == current_user.id
  end
end
