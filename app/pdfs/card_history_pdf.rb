require "prawn/table"

class CardHistoryPdf < Prawn::Document
  def initialize(cards)
    super(top_margin: 50)
    @cards = cards
    header
    table_content
  end

  def header
    text "List of Deleted Cards", size: 20, style: :bold, align: :center
    move_down 20
    generated_text = "Generated at: #{Time.current.strftime('%B %d, %Y %I:%M %p')}"
    text generated_text, align: :right, size: 10, style: :italic
    move_down 10
  end

  def table_content
    if @cards.empty?
      move_down 20
      text "No cards found.", size: 12, style: :italic, align: :center
    else
      table data_rows, header: true, width: bounds.width do
        row(0).font_style = :bold
        self.row_colors = ["F0F0F0", "FFFFFF"]
        self.cell_style = {
          borders: [:left, :right, :top, :bottom],
          padding: 5,
          # These settings help prevent splitting words mid-letter.
          overflow: :shrink_to_fit,
          min_font_size: 9,
          disable_wrap_by_char: true
        }
      end
    end
  end

  def data_rows
    # Table header row and data rows
    [["#", "Card Number", "Name", "Card Type", "Deletion Date", "Status"]] +
      @cards.each_with_index.map do |card, index|
        [
          index + 1,
          card.uid,
          card.user.present? ? [card.user.firstname, card.user.middlename, card.user.lastname].reject(&:blank?).join(" ") : "No Owner",
          card.uid_type.humanize,
          card.deleted_at.in_time_zone('Asia/Manila').strftime('%Y-%m-%d'),
          card.status
        ]
      end
  end
end
