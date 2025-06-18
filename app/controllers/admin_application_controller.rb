class AdminApplicationController < ActionController::Base
  before_action :authenticate_user!, except: [:create, :update, :new, :card_scan]

  before_action :set_role_user

  private

  def set_role_user
    @role_user = current_user&.role
  end
end