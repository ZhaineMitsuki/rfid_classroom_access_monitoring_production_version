# frozen_string_literal: true

class Admin::Devise::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: [:create, :new]
  skip_before_action :require_no_authentication, only: [:create]
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    sign_out(current_user) if current_user # prevent "already signed in" error

    # First check if user exists and has proper role
    user = User.find_by(email: params[:user][:email])
    
    if user.nil? || (!user.admin? && !user.super_admin?)
      # User doesn't exist or doesn't have admin privileges
      flash.now[:alert] = 'Invalid account or insufficient privileges.'
      self.resource = resource_class.new(sign_in_params)
      clean_up_passwords(resource)
      render :new, status: :unprocessable_entity
      return
    end

    # User exists and has admin role, now let Devise handle password validation
    # Override success callback to add welcome message
    self.resource = warden.authenticate!(auth_options)
    
    if resource
      # Authentication successful
      set_flash_message!(:notice, :signed_in) if is_flashing_format?
      sign_in(resource_name, resource)
      flash[:notice] = "Welcome, #{resource.firstname}"
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  rescue Warden::NotAuthenticated
    # Authentication failed (wrong password)
    flash.now[:alert] = 'Invalid email or password.'
    self.resource = resource_class.new(sign_in_params)
    clean_up_passwords(resource)
    render :new, status: :unprocessable_entity
  end

  # DELETE /resource/sign_out
  def destroy
    super
  end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
