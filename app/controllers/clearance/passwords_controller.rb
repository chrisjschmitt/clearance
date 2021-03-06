class Clearance::PasswordsController < ApplicationController
  unloadable

  before_filter :forbid_missing_token,     :only => [:edit, :update]
  before_filter :forbid_non_existent_user, :only => [:edit, :update]
  filter_parameter_logging :password, :password_confirmation

  def new
    render :template => 'passwords/new'
  end

  def create
    if user = ::User.find_by_email(params[:password][:email])
      user.forgot_password!
      ::ClearanceMailer.deliver_change_password user
      flash[:notice] = "You will receive an email within the next few minutes. " <<
                       "It contains instructions for changing your password."
      redirect_to url_after_create
    else
      flash.now[:notice] = "Unknown email"
      render :template => 'passwords/new'
    end
  end

  def edit
    @user = ::User.find_by_id_and_token(params[:user_id], params[:token])
    render :template => 'passwords/edit'
  end

  def update
    @user = ::User.find_by_id_and_token(params[:user_id], params[:token])

    if @user.update_password(params[:user][:password], 
                             params[:user][:password_confirmation])
      @user.confirm_email! unless @user.email_confirmed?
      sign_user_in(@user)
      redirect_to url_after_update
    else
      render :template => 'passwords/edit'
    end
  end

  private

  def forbid_missing_token
    if params[:token].blank?
      raise ActionController::Forbidden, "missing token"
    end
  end

  def forbid_non_existent_user
    unless ::User.find_by_id_and_token(params[:user_id], params[:token])
      raise ActionController::Forbidden, "non-existent user"
    end
  end

  def url_after_create
    new_session_url
  end

  def url_after_update
    root_url
  end

end
