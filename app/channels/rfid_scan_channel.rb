class RfidScanChannel < ApplicationCable::Channel
  def subscribed
    stream_from "rfid_scans"
  end
end

