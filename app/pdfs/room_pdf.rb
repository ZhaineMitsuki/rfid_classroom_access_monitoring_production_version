require "prawn/table"

class RoomPdf < Prawn::Document
  def initialize(rooms)
    super(top_margin: 50)
    @rooms = rooms
    header
    table_content
  end

  def header
    text "List of Rooms", size: 20, style: :bold, align: :center
    move_down 20
    generated_text = "Generated at: #{Time.current.strftime('%B %d, %Y %I:%M %p')}"
    text generated_text, align: :right, size: 10, style: :italic
    move_down 10
  end

  def table_content
    if @rooms.empty?
      move_down 20
      text "No rooms found.", size: 12, style: :italic, align: :center
    else
      table data_rows, header: true, width: bounds.width do
        row(0).font_style = :bold
        self.row_colors = ["F0F0F0", "FFFFFF"]
        self.cell_style = {
          borders: [:left, :right, :top, :bottom],
          padding: 5,
          overflow: :shrink_to_fit,
          min_font_size: 9,
          disable_wrap_by_char: true
        }
      end
    end
  end

  def data_rows
    # Table headers and data rows
    [["#", "Room Number", "Status", "Registered Date"]] +
      @rooms.each_with_index.map do |room, index|
        [
          index + 1,
          room.room_number,
          room.room_status,
          room.created_at.strftime('%Y-%m-%d')
        ]
      end
  end
end
