require "prawn/table"

class ProfessorHistoryPdf < Prawn::Document
  def initialize(users)
    super(top_margin: 50)
    @users = users
    header
    table_content
  end

  def header
    text "List of Deleted Professors", size: 20, style: :bold, align: :center
    move_down 20
    generated_text = "Generated at: #{Time.current.strftime('%B %d, %Y %I:%M %p')}"
    text generated_text, align: :right, size: 10, style: :italic
    move_down 10
  end

  def table_content
    if @users.empty?
      move_down 20
      text "No records found.", size: 12, style: :italic, align: :center
    else
      table data_rows, header: true, width: bounds.width do
        row(0).font_style = :bold
        self.row_colors = ["F0F0F0", "FFFFFF"]

        self.cell_style = {
          borders: [:left, :right, :top, :bottom],
          padding: 3,
          overflow: :shrink_to_fit,
          min_font_size: 9,
          disable_wrap_by_char: true
        }
      end
    end
  end

  def data_rows
    # Table headers
    [["#", "Name", "College", "Email", "Deletion Date", "Status"]] +
      @users.each_with_index.map do |user, index|
        [
          index + 1,
          [user.firstname, user.middlename, user.lastname].reject(&:blank?).join(" "),
          user.academic_college,
          user.email,
          user.deleted_at.strftime('%Y-%m-%d'),
          user.active? ? "Active" : "Inactive"
        ]
      end
  end
end
