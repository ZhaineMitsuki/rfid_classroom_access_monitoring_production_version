class Admin::RoomsController < AdminApplicationController
  before_action :set_params, only: [:create, :update]
  before_action :set_room, only: [:edit, :update, :destroy]

  def index
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
    rooms_query = Room.where(remarks: nil)
                      .order(Arel.sql("GREATEST(EXTRACT(EPOCH FROM created_at), EXTRACT(EPOCH FROM updated_at)) DESC, room_number ASC"))
    rooms_query = rooms_query.where('room_number::text LIKE ?', "%#{params[:room_number].strip}%") if params[:room_number].present?
    rooms_query = rooms_query.where(room_status: params[:room_status]) if params[:room_status].present?

    # For HTML, paginate the results.
    @rooms = rooms_query.page(params[:page]).per(10)

    respond_to do |format|
      format.html  # renders your index.html.erb for HTML requests
      format.pdf do
        # Pass the full, unpaginated filtered set to the PDF generator.
        pdf = RoomPdf.new(rooms_query)
        send_data pdf.render,
                  filename: "rooms.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def new
    @room = Room.new
  end

  def create
    @room = Room.new(set_params)

    if @room.save
      redirect_to rooms_path, notice: "Room successfully created."
    else
      redirect_to new_room_path, alert: "Failed to create room: #{@room.errors.full_messages.to_sentence}"
    end
  end

  def edit
    if @room.Unavailable?
      redirect_to rooms_path, alert: "Editing is disabled for unavailable rooms."
    elsif @room.remarks.present?
      redirect_to history_room_path, alert: "Editing is disabled for archived rooms."
    end
  end

  def update
    if @room.update(set_params)
      flash[:notice] = "Room successfully updated."
      redirect_to edit_room_path
    else
      flash[:alert] = "Failed to update room: #{@room.errors.full_messages.join(', ')}"
      redirect_to edit_room_path, status: :unprocessable_entity
    end
  end

  def destroy
    if @room.remarks.nil?
      archived_room_number = @room.room_number.to_i + Time.now.to_i

      ActiveRecord::Base.transaction do
        @room.update!(remarks: 'archived', deleted_at: Time.now, room_status: 0, original_room_number: @room.room_number, room_number: archived_room_number)
        @room.time_tracks.update_all(remarks: 'archived', deleted_at: Time.now)
        @room.schedules.update_all(remarks: 'archived', deleted_at: Time.now)
      end
      flash[:notice] = 'Room and all associated records have been archived.'
      redirect_to rooms_path
    elsif @room.archived?
      if @room.destroy
        flash[:notice] = 'Archived room permanently deleted.'
        redirect_to history_room_path
      else
        flash[:alert] = "Failed to delete the room: #{@room.errors.full_messages.join(', ')}"
        redirect_to history_room_path
      end
    end
  end

  def toggle_status
    @room = Room.find(params[:id])

    if @room.remarks.present?
      redirect_to history_room_path, alert: "Cannot change status of an archived room."
      return
    end

    raw_status = params[:room_status].to_s.strip

    unless Room.room_statuses.key?(raw_status)
      flash[:alert] = "Invalid room status value: #{raw_status.inspect}"
      redirect_to rooms_path and return
    end

    if @room.update(room_status: raw_status)
      flash[:notice] = "Room #{@room.room_number} has been updated to #{raw_status}."
    else
      flash[:alert] = "Failed to update room status."
    end

    redirect_to rooms_path
  end

  private

  def set_room
    @room = Room.find(params[:id])
  end

  def set_params
    params.require(:room).permit(:room_status, :room_number)
  end
end