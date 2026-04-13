class Users::ProfilesController < ApplicationController
  before_action :set_user_and_profile

  def edit
    authorize @profile
  end

  def update
    authorize @profile
    if @profile.update(profile_params)
      redirect_to user_path(@user), notice: "Profile updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_user_and_profile
    @user = User.find(params[:user_id])
    @profile = @user.profile
  end

  def profile_params
   params.require(:profile).permit(:display_name, :bio, :location, :avatar)
  end
end
