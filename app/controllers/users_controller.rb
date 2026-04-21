class UsersController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @users = User.includes(:profile).where.not(id: current_user.id)

    if @query.present?
      @users = @users.where("username ILIKE ?", "%#{@query}%")
    end

    @users = @users.order(:username)
    @outgoing_follows = current_user.sent_follow_requests.index_by(&:receiver_id)
  end

  def show
    @user = User.find(params[:id])
    @follow = current_user.sent_follow_requests.find_by(receiver_id: @user.id)
    @is_self = current_user.id == @user.id

    @pagy, @posts = pagy(
      @user.posts
           .includes(:likes, :comments, user: { profile: { avatar_attachment: :blob } }, image_attachment: :blob)
           .order(created_at: :desc)
    )
  end

  def followers
    @user = User.find(params[:id])
    @pagy, @users = pagy(
      @user.followers.includes(:profile).order(:username)
    )
    render :connection_list, locals: { title: "#{@user.username}'s followers" }
  end

  def following
    @user = User.find(params[:id])
    @pagy, @users = pagy(
      @user.following.includes(:profile).order(:username)
    )
    render :connection_list, locals: { title: "People #{@user.username} follows" }
  end
end
