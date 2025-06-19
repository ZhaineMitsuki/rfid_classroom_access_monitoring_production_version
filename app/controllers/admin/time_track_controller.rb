class Admin::TimeTrackController < AdminApplicationController
  before_action :authenticate_user!
  before_action :time_track_params, only: [:create, :update]
  before_action :set_time_track, only: [:edit, :update, :destroy]

  def index
    if params[:encrypted_params].present?
      begin
        decrypted_params = Rack::Utils.parse_nested_query(EncryptionHelper.decrypt(params[:encrypted_params]))
        params.merge!(decrypted_params)
      rescue => e
        Rails.logger.error "Error decrypting parameters: #{e.message}"
        flash[:error] = "Invalid parameters."
        redirect_to time_track_index_path and return
      end
    end

    # Fetch initial data for filters
    @rooms = Room.all
    @professors = User.where(role: "professor")

    # Base query: includes relations, no super_admins
    time_tracks = TimeTrack.includes(:room, :user)
                           .where(remarks: nil)
                           .where.not(users: { role: :super_admin })

    # Apply filters
    if params[:room_number].present?
      time_tracks = time_tracks.joins(:room)
                               .where('rooms.room_number::text LIKE ?', "%#{params[:room_number].strip}%")
    end

    if params[:professor_name].present?
      prof_query = params[:professor_name].downcase.strip
      time_tracks = time_tracks.joins(:user).where(
        "LOWER(users.firstname) LIKE :query OR LOWER(users.lastname) LIKE :query OR LOWER(users.firstname || ' ' || users.lastname) LIKE :query",
        query: "%#{prof_query}%"
      )
    end

    if params[:status].present?
      time_tracks = time_tracks.where(status: params[:status])
    end

    # Date filter — optional only if parameters are present
    if params[:start_date].present? && params[:end_date].present?
      time_tracks = time_tracks.where("DATE(time_tracks.created_at) BETWEEN ? AND ?", params[:start_date], params[:end_date])
    elsif params[:start_date].present?
      time_tracks = time_tracks.where("DATE(time_tracks.created_at) = ?", params[:start_date])
    elsif params[:end_date].present?
      time_tracks = time_tracks.where("DATE(time_tracks.created_at) <= ?", params[:end_date])
    end
    # ✅ No ELSE: so no date condition by default

    # Order by time_in descending
    time_tracks = time_tracks.joins(:room).order(time_in: :desc)

    # Pagination for HTML
    @time_tracks = time_tracks.page(params[:page]).per(10)

    respond_to do |format|
      format.html # renders index.html.erb
      format.pdf do
        pdf = TimeTrackPdf.new(time_tracks, params[:start_date], params[:end_date])
        send_data pdf.render,
                  filename: "time_tracks.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def edit
  end

  def update
    if @time_track.update(time_track_params)
      flash[:success] = "Time Track updated successfully."
      redirect_to time_track_index_path
    else
      flash[:error] = "Failed to update Time Track."
      render :edit
    end
  end

  def destroy
    if @time_track.destroy
      flash[:success] = "Time Track deleted successfully."
    else
      flash[:error] = "Failed to delete Time Track."
    end
    redirect_to time_track_index_path
  end

  private

  def set_time_track
    @time_track = TimeTrack.find(params[:id])
  end

  def time_track_params
    params.require(:time_track).permit(:user_id, :room_id, :time_in, :time_out, :status)
  end
end
