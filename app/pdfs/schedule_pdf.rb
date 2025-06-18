require "prawn/table"

class SchedulePdf < Prawn::Document
  def initialize(schedules)
    super(top_margin: 50)
    @schedules = schedules
    header
    table_content
  end

  def header
    text "List of Schedules", size: 14, style: :bold, align: :center
    move_down 20
    generated_text = "Generated at: #{Time.current.strftime('%B %d, %Y %I:%M %p')}"
    text generated_text, align: :right, size: 9, style: :italic
    move_down 10
  end

  def table_content
    if @schedules.empty?
      move_down 20
      text "No schedules found.", size: 12, style: :italic, align: :center
    else
      table data_rows, header: true, width: bounds.width do
        row(0).font_style = :bold
        self.row_colors = ["F0F0F0", "FFFFFF"]
        self.cell_style = {
          borders: [:left, :right, :top, :bottom],
          padding: 5,
          size: 9.5,
          overflow: :shrink_to_fit,
          min_font_size: 9,
          disable_wrap_by_char: true
        }
      end
    end
  end

  def data_rows
    # Table header row followed by the data rows
    [["#", "Description", "Subject", "Day", "Start Time", "End Time", "Professor Name", "Room", "School Year"]] +
      @schedules.each_with_index.map do |schedule, index|
        professor_name = if schedule.user.present?
                           [schedule.user.firstname, schedule.user.middlename, schedule.user.lastname].reject(&:blank?).join(" ")
                         else
                           "No Owner"
                         end

        [
          index + 1,
          schedule.description.humanize,
          schedule.subject.upcase,
          schedule.day.humanize,
          schedule.start_time.strftime('%I:%M %p'),
          schedule.end_time.strftime('%I:%M %p'),
          professor_name,
          schedule.room&.room_number || "No Room",
          schedule.school_year || "No School Year"
        ]
      end
  end
end
