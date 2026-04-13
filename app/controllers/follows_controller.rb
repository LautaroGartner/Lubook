class FollowsController < ApplicationController
  before_action :set_follow, only: [ :destroy, :accept, :reject ]

  def create
    receiver = User.find(params[:receiver_id])

    if receiver == current_user
      redirect_back(fallback_location: users_path, alert: "You can't follow yourself.")
      return
    end

    @follow = current_user.sent_follow_requests.find_or_initialize_by(receiver: receiver)
    authorize @follow, :create?

    if @follow.persisted?
      redirect_back(fallback_location: users_path, notice: "Request already sent.")
    elsif @follow.save
      redirect_back(fallback_location: users_path, notice: "Follow request sent.")
    else
      redirect_back(fallback_location: users_path, alert: @follow.errors.full_messages.to_sentence)
    end
  end

  def destroy
    authorize @follow
    @follow.destroy
    redirect_back(fallback_location: users_path, notice: "Unfollowed.")
  end

  def accept
    authorize @follow
    @follow.update!(status: :accepted)
    redirect_back(fallback_location: users_path, notice: "Follow request accepted.")
  end

  def reject
    authorize @follow
    @follow.destroy
    redirect_back(fallback_location: users_path, notice: "Follow request rejected.")
  end

  private

  def set_follow
    @follow = Follow.find(params[:id])
  end
end
