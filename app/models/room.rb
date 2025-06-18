class Room < ApplicationRecord
  has_many :schedules,  dependent: :destroy
  has_many :time_tracks, dependent: :destroy

  before_destroy :destroy_archived_associations

  enum room_status: {Unavailable: 0, Available: 1}
  enum remarks: { archived: 0, restored: 1 }

  validates :room_number, presence: true, uniqueness: true, numericality: { only_integer: true, greater_than: 0 }
  validates :room_status, presence: true

  def update_room_status
    room.broadcast_status_update!

    # Also broadcast via RoomStatusChannel for JS DOM updates
    ActionCable.server.broadcast("RoomStatusChannel", [
      { room_id: room.id, status: room.current_status }
    ])
  end

  def current_status
    return "unavailable" if Unavailable?

    latest_track = time_tracks.order(updated_at: :desc).first

    if latest_track.nil?
      "vacant"
    elsif latest_track.time_out.present?
      "vacant"
    else
      "time_in"
    end
  end

  def destroy_archived_associations
    schedules.where(remarks: 'archived').destroy_all
    time_tracks.where(remarks: 'archived').destroy_all
  end
end