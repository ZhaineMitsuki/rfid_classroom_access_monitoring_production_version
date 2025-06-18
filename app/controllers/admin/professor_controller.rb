class Admin::ProfessorController < AdminApplicationController
  before_action :authenticate_user!, except: [:create]
  before_action :set_user, only: [:edit, :update, :destroy]

  def index
    if params[:encrypted_params].present?
      begin
        decrypted_params = Rack::Utils.parse_nested_query(EncryptionHelper.decrypt(params[:encrypted_params]))
        params.merge!(decrypted_params)
      rescue => e
        Rails.logger.error "Error decrypting parameters: #{e.message}"
        flash[:error] = "Invalid parameters."
        redirect_to professor_index_path and return
      end
    end

        users_query = User.where(remarks: nil)
                       .where.not(users: { role: :super_admin })
                       .order(Arel.sql("GREATEST(EXTRACT(EPOCH FROM users.created_at), EXTRACT(EPOCH FROM users.updated_at)) DESC"))

    if params[:fullname].present?
      search_query = params[:fullname].strip.downcase
      users_query = users_query.where(
        'LOWER(firstname) LIKE :query OR LOWER(middlename) LIKE :query OR LOWER(lastname) LIKE :query OR ' \
          'LOWER(firstname || \' \' || COALESCE(middlename, \'\') || \' \' || lastname) LIKE :query OR ' \
          'LOWER(firstname || \' \' || lastname) LIKE :query',
        query: "%#{search_query}%"
      )
    end

    users_query = users_query.where(academic_college: params[:academic_college]) if params[:academic_college].present?
    users_query = users_query.where(role: params[:role]) if params[:role].present?

    # Assign the filtered query to the instance variable paginated for HTML
    @users = users_query.page(params[:page]).per(10)

    respond_to do |format|
      format.html  # Render HTML using paginated @users
      format.pdf do
        # Use the full filtered dataset (users_query) for PDF
        pdf = ProfessorPdf.new(users_query)
        send_data pdf.render,
                  filename: "professors.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    # Only assign default role if not a super admin
    @user.role = "professor" unless current_user.super_admin?
    @user.status = "active"
    @user.api_token = "6dbe948bb56f1d6827fbbd8321c7ad14"

    surname = @user.lastname&.upcase || "DEFAULT"
    generated_password = "#{surname}123!"

    @user.password = generated_password unless current_user.super_admin?
    @user.password_confirmation = generated_password unless current_user.super_admin?

    if @user.save
      flash[:notice] = "Professor #{@user.firstname} #{@user.lastname} created successfully!"
      redirect_to professor_index_path
    else
      flash[:alert] = "Failed to create professor: #{@user.errors.full_messages.join(', ')}"
      redirect_to professor_index_path
    end
  end

  def edit;
    if @user.inactive?
      redirect_to professor_index_path, alert: "Editing is disabled for inactive professors."
    elsif @user.remarks.present?
      redirect_to history_professor_path, alert: "Editing is disabled for archived professors."
    end
  end

  def update
    if @user.update(user_params)
      flash[:notice] = "Professor updated successfully!"
      redirect_to edit_professor_path(@user)
    else
      flash[:alert] = "Failed to update professor: #{@user.errors.full_messages.join(', ')}"
      render :edit
    end
  end

  def destroy
    # Prevent deleting other super admins
    if @user.super_admin?
      flash[:alert] = "Super Admin account cannot be deleted."
      redirect_to professor_index_path and return
    end

    # Prevent Admins from deleting Admins or Super Admins
    if current_user.admin? && (@user.admin? || @user.super_admin?)
      flash[:alert] = "You are not authorized to delete this account."
      redirect_to professor_index_path and return
    end

    # Optional: Prevent self-deletion
    if current_user == @user
      flash[:alert] = "You cannot delete your own account."
      redirect_to professor_index_path and return
    end

    if @user.remarks.nil?
      archived_email = @user.email.sub('@', "_archived_#{Time.now.to_i}@")

      ActiveRecord::Base.transaction do
        @user.update!(remarks: 'archived', deleted_at: Time.now, status: 0, original_email: @user.email, email: archived_email)
        @user.cards.update_all(remarks: 'archived', deleted_at: Time.now, status: 0)
        @user.schedules.update_all(remarks: 'archived', deleted_at: Time.now)
        @user.time_tracks.update_all(remarks: 'archived', deleted_at: Time.now)
      end
      flash[:notice] = 'Professor and all associated records have been archived.'
      redirect_to professor_index_path
    elsif @user.archived?
      if @user.destroy
        flash[:notice] = 'Archived professor permanently deleted.'
        redirect_to history_professor_path
      else
        flash[:alert] = "Failed to delete user: #{@user.errors.full_messages.join(', ')}"
      end
      redirect_to history_professor_path
    end
  end

  def toggle_status
    @user = User.find(params[:id])

    if @user.remarks.present?
      redirect_to history_professor_path, alert: "Cannot change status of an archived professor."
      return
    end

    new_status = params[:status] == 'active' ? 'active' : 'inactive'
    @user.update(status: new_status)

    if new_status == 'active'
      @user.cards.update_all(status: 1)
    else
      @user.cards.update_all(status: 0)
    end

    flash[:notice] = "#{@user.firstname}'s status and associated cards have been updated to #{new_status.capitalize}."
    redirect_to professor_index_path
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :firstname, :middlename, :lastname,
      :academic_college, :email, :role, :password, :password_confirmation
    )
  end
end