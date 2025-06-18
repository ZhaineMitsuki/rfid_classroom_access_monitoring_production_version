class Admin::HistoryController < AdminApplicationController
  def index
  end

  def professor
    if params[:encrypted_params].present?
      begin
        decrypted_params = Rack::Utils.parse_nested_query(EncryptionHelper.decrypt(params[:encrypted_params]))
        params.merge!(decrypted_params)
      rescue => e
        Rails.logger.error "Error decrypting parameters: #{e.message}"
        flash[:error] = "Invalid parameters."
        redirect_to history_professor_path and return
      end
    end

    users_query = User.where(remarks: 'archived')
                      .where.not(users: { role: :super_admin })
                      .order(:firstname)

    if params[:fullname].present?
      search_query = params[:fullname].strip.downcase
      users_query = users_query.where(
        'LOWER(firstname) LIKE :query OR LOWER(middlename) LIKE :query OR LOWER(lastname) LIKE :query OR ' \
          'LOWER(CONCAT(firstname, \' \', middlename, \' \', lastname)) LIKE :query OR ' \
          'LOWER(CONCAT(firstname, \' \', lastname)) LIKE :query',
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
        pdf = ProfessorHistoryPdf.new(users_query)
        send_data pdf.render,
                  filename: "professor_history.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def card
    if params[:encrypted_params].present?
      begin
        decrypted_params = Rack::Utils.parse_nested_query(EncryptionHelper.decrypt(params[:encrypted_params]))
        params.merge!(decrypted_params)
      rescue => e
        Rails.logger.error "Error decrypting parameters: #{e.message}"
        flash[:error] = "Invalid parameters."
        redirect_to history_card_path and return
      end
    end

    # Build the base query and then filter it.
    cards_query = Card.includes(:user).where(remarks: 'archived').order('users.firstname ASC, cards.created_at ASC')
    filtered_cards = filter_cards(cards_query)

    # For HTML, paginate the results; for PDF, use the full filtered set.
    @cards = filtered_cards.page(params[:page]).per(10)

    respond_to do |format|
      format.html
      format.pdf do
        pdf = CardHistoryPdf.new(filtered_cards)
        send_data pdf.render,
                  filename: "cards.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def room
    if params[:encrypted_params].present?
      begin
        decrypted_params = Rack::Utils.parse_nested_query(EncryptionHelper.decrypt(params[:encrypted_params]))
        params.merge!(decrypted_params)
      rescue => e
        Rails.logger.error "Error decrypting parameters: #{e.message}"
        flash[:error] = "Invalid parameters."
        redirect_to rooms_path and return
      end
    end

    # Build the base, filtered query.
    rooms_query = Room.where(remarks: 'archived').order(:room_number)
    rooms_query = rooms_query.where('room_number::text LIKE ?', "%#{params[:room_number].strip}%") if params[:room_number].present?
    rooms_query = rooms_query.where(room_status: params[:room_status]) if params[:room_status].present?

    # For HTML, paginate the results.
    @rooms = rooms_query.page(params[:page]).per(10)

    respond_to do |format|
      format.html  # renders your index.html.erb for HTML requests
      format.pdf do
        # Pass the full, unpaginated filtered set to the PDF generator.
        pdf = RoomHistoryPdf.new(rooms_query)
        send_data pdf.render,
                  filename: "rooms.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def schedule
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
    filtered_schedules = Schedule.includes(:user, :room).where(remarks: 'archived')
                                 .joins(:room)
                                 .where(rooms: { room_status: Room.room_statuses[:Available] }) # <- This line filters only active rooms
                                 .order(Arel.sql("day ASC, school_year ASC, rooms.room_number ASC,
                                              TO_CHAR(start_time, 'AM') DESC,
                                              TO_CHAR(start_time, 'HH12:MI AM') DESC"))

    # Apply filters if present.
    filtered_schedules = filtered_schedules.where(day: params[:day]) if params[:day].present?
    filtered_schedules = filtered_schedules.where(room_id: params[:room_id]) if params[:room_id].present?
    filtered_schedules = filtered_schedules.where(school_year: params[:school_year]) if params[:school_year].present?

    if params[:professor_name].present?
      professor_query = params[:professor_name].downcase.strip
      filtered_schedules = filtered_schedules.joins(:user).where(
        "LOWER(users.firstname) LIKE :query OR LOWER(users.lastname) LIKE :query OR LOWER(CONCAT(users.firstname, \' \', users.lastname)) LIKE :query",
        query: "%#{professor_query}%"
      )
    end

    # For HTML, paginate the filtered query (e.g., 10 per page).
    @schedules = filtered_schedules.page(params[:page]).per(10)

    respond_to do |format|
      format.html  # renders index.html.erb using @schedules (paginated)
      format.pdf do
        pdf = ScheduleHistoryPdf.new(filtered_schedules)  # full filtered set (no pagination)
        send_data pdf.render,
                  filename: "schedules.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  private

  def filter_cards(scope)
    scope = scope.where(cards: { uid: params[:uid] }) if params[:uid].present?
    scope = scope.where(status: params[:status]) if params[:status].present?

    if params[:fullname].present?
      q = "%#{params[:fullname].strip.downcase}%"
      scope = scope.joins(:user).where(
        'LOWER(users.firstname) LIKE :q OR LOWER(users.middlename) LIKE :q OR LOWER(users.lastname) LIKE :q OR ' \
          'LOWER(CONCAT(users.firstname, \' \', users.middlename, \' \', users.lastname)) LIKE :q OR ' \
          'LOWER(CONCAT(users.firstname, \' \', users.lastname)) LIKE :q', q: q
      )
    end
    scope
  end
end
