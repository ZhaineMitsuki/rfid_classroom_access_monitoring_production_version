class RoomStatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from "RoomStatusChannel"
  end

  def unsubscribed
    # Cleanup when channel is unsubscribed if needed.
  end
end