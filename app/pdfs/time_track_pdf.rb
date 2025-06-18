require "prawn/table"

class TimeTrackPdf < Prawn::Document
  def initialize(time_tracks, start_date, end_date)
    super(top_margin: 50)
    @time_tracks = time_tracks
    @start_date = start_date
    @end_date = end_date
    header
    table_content
  end

  def header
    text "Classroom Access Log", size: 20, style: :bold, align: :center
    move_down 20
    date_range_text = if @start_date.present? && @end_date.present?
                        "Date Range: #{@start_date} to #{@end_date}"
                      elsif @start_date.present?
                        "From: #{@start_date}"
                      elsif @end_date.present?
                        "Up to: #{@end_date}"
                      else
                        "Date: #{Date.current.strftime('%Y-%m-%d')}"
                      end

    generated_text = "Generated at: #{Time.current.strftime('%B %d, %Y %I:%M %p')}"

    bounding_box([0, cursor], width: bounds.width, height: 20) do
      text_box date_range_text, at: [0, cursor], size: 10, style: :italic, width: bounds.width / 2
      text_box generated_text, at: [bounds.width / 2, cursor], size: 10, align: :right, width: bounds.width / 2
    end
    move_down 0
  end

  def table_content
    table track_rows, header: true, width: bounds.width do
      row(0).font_style = :bold
      self.header = true
      self.row_colors = ["F0F0F0", "FFFFFF"]
      self.cell_style = { borders: [:left, :right, :top, :bottom], padding: 5 }
    end
  end

  def track_rows
    [["#", "Room", "Professor", "Date", "Time In", "Time Out", "Status"]] +
      @time_tracks.each_with_index.map do |track, index|
        time_in = begin
                    track.time_in.present? ? Time.parse(track.time_in).strftime("%I:%M %p") : "N/A"
                  rescue
                    track.time_in || "N/A"
                  end

        time_out = begin
                     track.time_out.present? ? Time.parse(track.time_out).strftime("%I:%M %p") : "N/A"
                   rescue
                     track.time_out || "N/A"
                   end

        [
          index + 1,
          track.room&.room_number || "N/A",
          "#{track.user.firstname} #{track.user.middlename} #{track.user.lastname}",
          track.created_at.strftime("%Y-%m-%d"),
          time_in,
          time_out,
          track.status.titleize
        ]
      end
  end
end
