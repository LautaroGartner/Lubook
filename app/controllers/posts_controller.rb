class PostsController < ApplicationController
  before_action :set_post, only: [ :show, :edit, :update, :destroy ]

  def show
    @comments = @post.comments.chronological.includes(:likes, :parent, user: { profile: { avatar_attachment: :blob } })
    @comment = Comment.new
  end

  def create
    @post = current_user.posts.build(post_params)
    authorize @post

    if @post.save
      redirect_to root_path, notice: "Posted."
    else
      redirect_to root_path, alert: @post.errors.full_messages.to_sentence
    end
  end

  def edit
    authorize @post, :update?
  end

  def update
    authorize @post, :update?
    if @post.update(post_params)
      redirect_to post_path(@post), notice: "Post updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @post
    @post.destroy
    respond_to do |format|
      format.turbo_stream { redirect_to root_path, notice: "Post deleted." }
      format.html { redirect_back fallback_location: root_path, notice: "Post deleted." }
    end
  end

  private

  def set_post
    @post = Post.includes(:user, :likes).find(params[:id])
  end

  def post_params
    params.require(:post).permit(:body, images: [])
  end
end
