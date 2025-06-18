class Admin::SchedulesController < AdminApplicationController
  before_action :set_params, only: [:create, :update]
  before_action :set_schedule, only: [:edit, :update, :destroy]

  def index
    if params[:encrypted_params].present?
      begin
        decrypted_params = Rack::Utils.parse_nested_query(EncryptionHelper.decrypt(params[:encrypted_params]))
        params.merge!(decrypted_params)
      rescue => e
        Rails.logger.error "Error decrypting parameters: #{e.message}"
        flash[:error] = "Invalid parameters."
        redirect_to schedules_path and return
      end
    end

    @days = Schedule.pluck(:day).uniq
    @users = User.all # Fetch all users as objects
    @rooms = Room.all # Fetch all rooms as objects
    @school_years = Schedule.distinct.pluck(:school_year).compact.sort

    # Build the base filtered query.
    filtered_schedules = Schedule.includes(:user, :room)
                                 .where(remarks: nil)
                                 .where.not(users: { role: :super_admin })
                                 .joins(:room)
                                 .where(rooms: { room_status: Room.room_statuses[:Available] })
                                 .order(Arel.sql("GREATEST(EXTRACT(EPOCH FROM schedules.created_at), EXTRACT(EPOCH FROM schedules.updated_at)) DESC,
                                                  day ASC, school_year ASC, rooms.room_number ASC,
                                                  TO_CHAR(start_time, 'AM') DESC,
                                                  TO_CHAR(start_time, 'HH12:MI AM') DESC"))

    # Apply filters if present.
    filtered_schedules = filtered_schedules.where(day: params[:day]) if params[:day].present?
    filtered_schedules = filtered_schedules.where(room_id: params[:room_id]) if params[:room_id].present?
    filtered_schedules = filtered_schedules.where(school_year: params[:school_year]) if params[:school_year].present?

    if params[:professor_name].present?
      professor_query = params[:professor_name].downcase.strip
      filtered_schedules = filtered_schedules.joins(:user).where(
        "LOWER(users.firstname) LIKE :query OR LOWER(users.lastname) LIKE :query OR LOWER(users.firstname || \' \' || users.lastname) LIKE :query",
        query: "%#{professor_query}%"
      )
    end

    # For HTML, paginate the filtered query (e.g., 10 per page).
    @schedules = filtered_schedules.page(params[:page]).per(10)

    respond_to do |format|
      format.html # renders index.html.erb using @schedules (paginated)
      format.pdf do
        pdf = SchedulePdf.new(filtered_schedules) # full filtered set (no pagination)
        send_data pdf.render,
                  filename: "schedules.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def new
    @schedule = Schedule.new
    @users = User.all
    @room_statuses = fetch_room_statuses
  end

  def create
    @schedule = Schedule.new(set_params)

    if @schedule.save
      flash[:notice] = "Schedule was successfully created."
      redirect_to schedules_path
    else
      flash[:alert] = "Failed to create schedule: #{@schedule.errors.full_messages.to_sentence}"
      @users = User.all
      @room_statuses = fetch_room_statuses
      redirect_to new_schedule_path
    end
  end

  def edit
    if @schedule.nil?
      redirect_to schedules_path, alert: "Schedule not found." and return
    end

    if @schedule.remarks.present?
      redirect_to history_schedule_path, alert: "Editing is disabled for archived schedules." and return
    end

    if @schedule.room&.Unavailable?
      redirect_to schedules_path, alert: "Editing is disabled for unavailable rooms." and return
    end

    @room_statuses = fetch_room_statuses
  end

  def update
    if @schedule.update(set_params)
      flash[:notice] = "Schedule was successfully updated."
      redirect_to edit_schedule_path
    else
      flash[:alert] = "Failed to update schedule: #{@schedule.errors.full_messages.to_sentence}"
      @room_statuses = fetch_room_statuses
      redirect_to edit_schedule_path
      @room_statuses = fetch_room_statuses
    end
  end

  def destroy
    if @schedule.remarks.nil?
      archived_school_year = @schedule.school_year.to_i + Time.now.to_i

      ActiveRecord::Base.transaction do
        @schedule.update!(remarks: 'archived', deleted_at: Time.current, original_school_year: @schedule.school_year, school_year: archived_school_year)
      end
      flash[:notice] = 'Schedule has been archived.'
      redirect_to schedules_path

    elsif @schedule.archived?
      if @schedule.destroy
        flash[:notice] = 'Archived schedule permanently deleted.'
        redirect_to history_schedule_path
      else
        flash[:alert] = "Failed to delete the schedule: #{@schedule.errors.full_messages.join(', ')}"
        redirect_to history_schedule_path
      end
    end
  end

  private

  def set_schedule
    @schedule = Schedule.find(params[:id])
  end

  def set_params
    params.require(:schedule).permit(:user_id, :description, :subject, :day, :start_time, :end_time, :room_id, :school_year, :semester, :year_level)
  end

  def fetch_room_statuses
    statuses = {}
    Room.includes(:time_tracks).each do |room|
      statuses[room.id] = room.Unavailable? ? "unavailable" : "vacant"
    end
    statuses
  end
end