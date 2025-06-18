# frozen_string_literal: true

class Admin::Devise::PasswordsController < Devise::PasswordsController
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    begin
      super
    rescue StandardError => e
      Rails.logger.error "Password reset email delivery failed: #{e.message}"
      
      # Check if email was found but delivery failed
      if resource && resource.persisted? && resource.errors.empty?
        flash[:notice] = "If your email address exists in our database, you will receive password reset instructions. (Note: Email delivery is currently being configured)"
        redirect_to new_user_session_path and return
      end
      
      # Show a generic success message for security (don't reveal if email exists)
      flash[:notice] = "If your email address exists in our database, you will receive password reset instructions."
      redirect_to new_user_session_path
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
