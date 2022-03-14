class Users::PasswordsController < Devise::PasswordsController
  protected

  def after_resetting_password_path_for(resource)
    sign_out
    flash[:notice] = "Your password has been changed successfully. Please log in with your new password"
    new_user_session_path
  end
end
