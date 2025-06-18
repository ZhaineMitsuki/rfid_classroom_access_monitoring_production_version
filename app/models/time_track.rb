class TimeTrack < ApplicationRecord
  belongs_to :user
  belongs_to :room
  belongs_to :card

  enum status: { time_in: 0, time_out: 1 }
  enum remarks: { archived: 0, restored: 1 }

  after_commit :update_room_status

  private

  def update_room_status
    Rails.logger.info "Broadcasting update for Room ID #{room.id}"

    status = room.current_status
    ActionCable.server.broadcast(
      "RoomStatusChannel",
      [
        {
          room_id: room.id,
          status: status
        }
      ]
    )
  end
end