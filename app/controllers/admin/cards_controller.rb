class Admin::CardsController < AdminApplicationController
  skip_before_action :verify_authenticity_token, only: [:card_scan]
  before_action :set_params, only: [:create, :update]
  before_action :set_card, only: [:edit, :destroy, :update]

  def index
    if params[:encrypted_params].present?
      begin
        decrypted_params = Rack::Utils.parse_nested_query(EncryptionHelper.decrypt(params[:encrypted_params]))
        params.merge!(decrypted_params)
      rescue => e
        Rails.logger.error "Error decrypting parameters: #{e.message}"
        flash[:error] = "Invalid parameters."
        redirect_to cards_path and return
      end
    end

    # Build the base query and then filter it.
    cards_query = Card.includes(:user)
                      .where(remarks: nil)
                      .where.not(users: { role: :super_admin })
                      .order(Arel.sql("GREATEST(EXTRACT(EPOCH FROM cards.created_at), EXTRACT(EPOCH FROM cards.updated_at)) DESC"))
    filtered_cards = filter_cards(cards_query)

    # For HTML, paginate the results; for PDF, use the full filtered set.
    @cards = filtered_cards.page(params[:page]).per(10)

    respond_to do |format|
      format.html
      format.pdf do
        pdf = CardPdf.new(filtered_cards)
        send_data pdf.render,
                  filename: "cards.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def new
    @card = Card.new
  end

  def create
    @card = Card.new(set_params)
    # The datetime here is optional, not tested yet. Rails automatically handles timestamps but if not, uncomment below.
    #@card.created_at = DateTime.now

    # if params[:card][:user_id].present?
    #   @card.user_id = params[:card][:user_id].to_i
    # end

    if @card.save
      flash[:notice] = "Card successfully created."
      redirect_to cards_path
    else
      flash[:alert] = "Failed to create card: #{@card.errors.full_messages.to_sentence}"
      redirect_to cards_path
    end
  end

  def edit
    if @card.Inactive?
      redirect_to cards_path, alert: "Editing is disabled for inactive cards."
    elsif @card.remarks.present?
      redirect_to history_card_path, alert: "Editing is disabled for archived cards."
    end
  end

  def update
    if @card.update(set_params)
      flash[:notice] = "Card successfully updated."
      redirect_to edit_card_path
    else
      flash[:alert] = "Failed to update room: #{@card.errors.full_messages.join(', ')}"
      redirect_to edit_card_path, status: :unprocessable_entity
    end
  end

  def destroy
    if @card.remarks.nil?
      archived_card_number = "#{@card.uid}_archived_#{Time.now.to_i}"

      ActiveRecord::Base.transaction do
        @card.update!(remarks: 'archived', deleted_at: Time.now, status: 0, original_uid: @card.uid, uid: archived_card_number)
        @card.time_tracks.update_all(remarks: 'archived', deleted_at: Time.now)
      end
      flash[:notice] = 'Card and all associated records have been archived.'
      redirect_to card_path
    elsif @card.archived?
      if @card.destroy
        flash[:notice] = 'Archived card permanently deleted.'
        redirect_to history_card_path
      else
        flash[:alert] = "Failed to delete the card: #{@user.errors.full_messages.join(', ')}"
        redirect_to history_card_path
      end
    end
  end

  def card_scan
    scanned_card_id = params[:uid]
    card = Card.find_by(uid: scanned_card_id)

    is_denied = card.present?
    ActionCable.server.broadcast("rfid_scans", {
      action: "display_uid",
      uid: scanned_card_id,
      denied: is_denied ? "The card is already in use" : nil
    })

    if is_denied
      render json: { success: false, error: "Card already in use" }
    else
      render json: { success: true, uid: scanned_card_id }
    end
  end

  def toggle_status
    @card = Card.find(params[:id])

    if @card.remarks.present?
      redirect_to history_card_path, alert: "Cannot change status of an archived card."
      return
    end

    new_status = params[:status] == 'Active' ? 'Active' : 'Inactive'

    if @card.user.active?
      @card.update(status: new_status)
      flash[:notice] = "Card #{@card.uid} status has been updated to #{new_status.capitalize}."
    redirect_to cards_path
    else
      flash[:alert] = "Card #{@card.uid} status update denied: Professor #{@card.user.firstname} #{@card.user.middlename} #{@card.user.lastname} is currently inactive."
      redirect_to cards_path
    end
  end

  private

  def set_params
    params.require(:card).permit(:uid, :user_id, :status, :uid_type)
  end

  def set_card
    @card = Card.find(params[:id])
  end

  def filter_cards(scope)
    scope = scope.where(cards: { uid: params[:uid] }) if params[:uid].present?
    scope = scope.where(status: params[:status]) if params[:status].present?

    if params[:fullname].present?
      q = "%#{params[:fullname].strip.downcase}%"
      scope = scope.joins(:user).where(
        'LOWER(users.firstname) LIKE :q OR LOWER(users.middlename) LIKE :q OR LOWER(users.lastname) LIKE :q OR ' \
                  'LOWER(users.firstname || \' \' || COALESCE(users.middlename, \'\') || \' \' || users.lastname) LIKE :q OR ' \
        'LOWER(users.firstname || \' \' || users.lastname) LIKE :q', q: q
      )
    end
    scope
  end
end