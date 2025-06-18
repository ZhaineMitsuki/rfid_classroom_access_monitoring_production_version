class Admin::RoomDisplayController < AdminApplicationController
  before_action :authenticate_user!, except: [:room_statuses]

  def index
    @rooms = Room.all.includes(:schedules).where(remarks: nil).order(:room_number)
    @room_statuses = fetch_room_statuses
  end

  def show
    @room = Room.find(params[:id])
    @schedules = @room.schedules.includes(:user).where(remarks: nil).order(:start_time)

    today_name = Time.zone.now.strftime("%A")
    @todays_schedules = @schedules.select { |s| s.day.to_s.strip.casecmp?(today_name) }

    @available_slots = calculate_available_time(@todays_schedules)

    @today_time_tracks = @room.time_tracks
                              .where(created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day, remarks: nil)
                              .order(time_in: :desc)
                              .page(params[:page])
                              .per(10)
  end

  def room_statuses
    rooms = Room.all.includes(:time_tracks)
    statuses = {}
    rooms.each { |room| statuses[room.id] = room.current_status }
    render json: statuses
  end

  private

  def fetch_room_statuses
    statuses = {}
    Room.includes(:time_tracks).each do |room|
      if room.room_status == "Unavailable"
        statuses[room.id] = "unavailable"
      else
        latest_time_track = room.time_tracks.order(created_at: :desc).first
        statuses[room.id] = latest_time_track&.status || "vacant"
      end
    end
    statuses
  end

  def calculate_available_time(schedules)
    visible_start = 6 * 60
    visible_end = 21 * 60

    # Collect all booked ranges
    booked_ranges = schedules.reject { |s| s.start_time == s.end_time }.map do |s|
      start_min = s.start_time.hour * 60 + s.start_time.min
      end_min = s.end_time.hour * 60 + s.end_time.min
      [start_min, end_min]
    end

    # Start with one full available range
    available_ranges = [[visible_start, visible_end]]

    # Subtract each booked range from available ranges
    booked_ranges.each do |booked_start, booked_end|
      updated = []
      available_ranges.each do |avail_start, avail_end|
        # No overlap
        if booked_end <= avail_start || booked_start >= avail_end
          updated << [avail_start, avail_end]
        else
          # Overlap logic
          updated << [avail_start, booked_start] if booked_start > avail_start
          updated << [booked_end, avail_end] if booked_end < avail_end
        end
      end
      available_ranges = updated
    end

    # Format result
    available_ranges
      .select { |start_min, end_min| end_min > start_min }
      .map { |start_min, end_min| "#{format_time(start_min)} - #{format_time(end_min)}" }
  end

  def format_time(minutes)
    Time.new(2000, 1, 1, minutes / 60, minutes % 60).strftime('%I:%M %p')
  end
end
