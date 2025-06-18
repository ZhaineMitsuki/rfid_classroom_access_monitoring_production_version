class Admin::RfidsController < AdminApplicationController
  before_action :authenticate_with_api_token, only: [:create]
  skip_before_action :verify_authenticity_token, only: [:create]
  before_action :authenticate_user!, except: [:create]

  def index; end

  def create
    rfid_uid = params[:uid]
    room_status = params[:room_status]
    room_id = params[:room_number]

    Rails.logger.info "🔔 RFID TAP RECEIVED → UID=#{rfid_uid}, ROOM=#{room_id}, STATUS=#{room_status}, AT=#{Time.current}"

    card = Card.find_by(uid: rfid_uid) # object
    room_number = Room.find(room_id)
    return render json: { message: "Card not registered" }, status: :unauthorized unless card

    if card.status == "Inactive"
      return render json: { message: "Card inactive" }, status: :conflict
    end

    if card.status == "Active"
      ActiveRecord::Base.transaction do
        if room_number.room_status == "Available"
          if room_status == "Lock"
            handle_lock(card, room_id, room_number)
          elsif room_status == "Unlock"
            handle_unlock(card, room_id, room_number)
          else
            render json: { message: "Invalid room status" }, status: :unprocessable_entity
          end
        else
          Rails.logger.info "❌ RFID TAP RECEIVED → UID=#{rfid_uid}, ROOM=#{room_id}, STATUS=#{room_status}, AT=#{Time.current}"
          Rails.logger.info "❌ Room Inactive"
          render json: {
            message: "Room is currently unavailable.",
          }, status: :locked
        end
      end
    end

  rescue StandardError => e
    logger.error "❌ RFID processing error: #{e.message}"
    render json: { message: "An unexpected error occurred" }, status: :internal_server_error
  end

  private

  def handle_lock(card, room_id, room_number)
    time_now = Time.current
    active_session = TimeTrack.find_by(card_id: card.id, room_id: room_id, time_out: nil)

    # If no active session, it will create a record
    if active_session.nil?
      # No active session, proceed to time in
      TimeTrack.create!(
        card_id: card.id,
        user_id: card.user_id,
        room_id: room_id,
        time_in: time_now
      )

      render json: {
        message: "Access granted",
        user_status: "Timed In",
        unlock: true,
        user: card.user.lastname,
        room_num: "Room #{room_number.room_number}",
        time: time_now.strftime('%I:%M %p')
      }, status: :ok

      # If there's an active session, it will continue the record
    elsif active_session.card_id == card.id
      # 🔁 Recover from power loss — allow re-entry by completing the unlock step
      # Make sure the session isn't marked as "inactive" if interrupted
      if active_session.time_out.nil?
        active_session.update!(time_out: time_now, status: 1)
        render json: {
          message: "Recovered session",
          user_status: "Time In Recovery",
          recovery: true,
          user: card.user.lastname,
          time: time_now.strftime('%I:%M %p')
        }, status: :ok
        else
          render json: {
            message: "Session already completed",
            access: false
          }, status: :forbidden
      end

    else
      render json: {
        message: "Room already in use by another card",
        access: false
      }, status: :forbidden
    end

  rescue StandardError => e
    logger.error "❌ Error in handle_lock: #{e.message}"
    render json: { message: "An unexpected error occurred" }, status: :internal_server_error
  end

  def handle_unlock(card, room_id, room_number)
    time_now = Time.current
    active_session = TimeTrack.find_by(card_id: card.id, room_id: room_id, time_out: nil)

    if active_session.nil?
      render json: {
        message: "No active session to time out for this card",
        access: false
      }, status: :forbidden
      return
    end

    if active_session.card_id != card.id
      render json: {
        message: "Access denied! Only the same card can time out.",
        access: false
      }, status: :forbidden
      return
    end

    if active_session.time_out.nil?
      active_session.update!(time_out: time_now, status: 1)

      render json: {
        message: "Access granted",
        user_status: "Timed Out",
        lock: true,
        user: card.user.lastname,
        room_num: "Room #{room_number.room_number}",
        time: time_now.strftime('%I:%M %p')
      }, status: :ok
    else
      render json: {
        message: "Session already completed",
        access: false
      }, status: :forbidden
    end

  rescue StandardError => e
    logger.error "❌ Error in handle_lock: #{e.message}"
    render json: { message: "An unexpected error occurred" }, status: :internal_server_error
  end

  def authenticate_with_api_token
    auth_header = request.headers['Authorization']
    token = auth_header&.split(' ')&.last
    head :unauthorized unless token && User.exists?(api_token: token)
  end
end
