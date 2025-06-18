class Admin::DashboardController < AdminApplicationController
  def index
    @total_users = User.where(remarks: nil).where.not(users: { role: :super_admin }).count
    @active_users = User.where(status: 1, remarks: nil).where.not(users: { role: :super_admin }).count
    @inactive_users = User.where(status: 0, remarks: nil).where.not(users: { role: :super_admin }).count

    @total_cards = Card.where(remarks: nil).count
    @active_cards = Card.where(status: 1, remarks: nil).count
    @inactive_cards = Card.where(status: 0, remarks: nil).count

    @total_rooms = Room.where(remarks: nil).count
    @available_rooms = Room.where(room_status: 1, remarks: nil).count
    @unavailable_rooms = Room.where(room_status: 0, remarks: nil).count

    room_status_counts = fetch_room_status_counts
    @vacant_rooms = room_status_counts[:vacant]
    @occupied_rooms = room_status_counts[:occupied]

    current_month = Date.today.month
    current_year = Date.today.year

    if current_month >= 7  # July to December
      @semester = "First Semester"
      @school_year = "#{current_year}-#{current_year + 1}"
      @semester_enum = :first_sem
    else  # January to June
      @semester = "Second Semester"
      @school_year = "#{current_year - 1}-#{current_year}"
      @semester_enum = :second_sem
    end

    @total_schedules = Schedule.where(
      school_year: @school_year,
      semester: Schedule.semesters[@semester_enum],
      remarks: nil
    ).count

    @recent_time_tracks = TimeTrack.includes(:user, :room, :card)
                                   .where(remarks: nil)
                                   .order(time_in: :desc)
                                   .page(params[:time_track_page])
                                   .per(5)

    today_system_day = Time.zone.today.wday

    @todays_schedules = Schedule
                          .left_joins(:room)
                          .includes(:user, :room)
                          .where(day: today_system_day, semester: Schedule.semesters[@semester_enum], school_year: @school_year, remarks: nil)
                          .order('rooms.room_number ASC, schedules.start_time ASC')
                          .page(params[:schedule_page])
                          .per(7)

    @active_rooms = Room.where(room_status: 1).includes(:schedules).order(room_number: :asc)
    @day_names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    @room_schedules = {}
    Room.where(room_status: 1).each do |room|
      schedules = Schedule.includes(:user)
                          .where(room_id: room.id, semester: Schedule.semesters[@semester_enum], school_year: @school_year, remarks: nil)
                          .order(:start_time)

      next if schedules.empty?
      @room_schedules[room.room_number.to_s] = schedules
    end
  end

  private

  def fetch_room_status_counts
    available_rooms = Room.where(room_status: 1, remarks: nil).pluck(:id)
    unavailable_count = Room.where(room_status: 0, remarks: nil).count
    occupied_room_ids = TimeTrack.where(status: 0, remarks: nil).distinct.pluck(:room_id).compact
    vacant_room_ids = available_rooms - occupied_room_ids

    {
      unavailable: unavailable_count,
      available: available_rooms.count,
      vacant: vacant_room_ids.count,
      occupied: occupied_room_ids.count
    }
  end
end