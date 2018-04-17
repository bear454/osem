# frozen_string_literal: true

module Admin
  class TicketsController < Admin::BaseController
    load_and_authorize_resource :conference, find_by: :short_title
    load_and_authorize_resource :ticket, through: :conference

    def index
      authorize! :update, Ticket.new(conference_id: @conference.id)
      @tickets_sold_distribution = @conference.tickets_sold_distribution
      @tickets_turnover_distribution = @conference.tickets_turnover_distribution
    end

    def new
      @ticket = @conference.tickets.new
    end

    def create
      @ticket = @conference.tickets.new(ticket_params)
      if @ticket.save(ticket_params)
        redirect_to admin_conference_tickets_path(conference_id: @conference.short_title),
                    notice: 'Ticket successfully created.'
      else
        flash.now[:error] = "Creating Ticket failed: #{@ticket.errors.full_messages.join('. ')}."
        render :new
      end
    end

    def edit; end

    def update
      if @ticket.update_attributes(ticket_params)
        redirect_to admin_conference_tickets_path(conference_id: @conference.short_title),
                    notice: 'Ticket successfully updated.'
      else
        flash.now[:error] = "Ticket update failed: #{@ticket.errors.full_messages.join('. ')}."
        render :edit
      end
    end

    def give
      ticket_purchase = @ticket.ticket_purchases.new(gift_ticket_params)
      recipient = ticket_purchase.user
      if ticket_purchase.save
        redirect_to admin_conference_ticket_path(@conference, @ticket),
          notice: "#{view_context.link_to(recipient.name, admin_user_path(recipient))} was given a #{@ticket.title} ticket.".html_safe
      else
        redirect_back fallback_location: admin_conference_ticket_path(@ticket), error: "Unable to give #{view_context.link_to(recipient.name, admin_user_path(recipient))} a #{@ticket.title} ticket: #{ticket_purchase.errors.full_messages.to_sentence}".html_safe
      end
    end

    def destroy
      if @ticket.destroy
        redirect_to admin_conference_tickets_path(conference_id: @conference.short_title),
                    notice: 'Ticket successfully destroyed.'
      else
        redirect_to admin_conference_tickets_path(conference_id: @conference.short_title),
                    error: 'Ticket was successfully destroyed.' \
                    "#{@ticket.errors.full_messages.join('. ')}."
      end
    end

    private

    def ticket_params
      params.require(:ticket).permit(
        :conference, :conference_id,
        :title, :url, :description,
        :price_cents, :price_currency, :price,
        :registration_ticket, :visible, :badge_ribbon,
        materials: []
      )
    end

    def gift_ticket_params
      response = params.require(:ticket_purchase).permit(
        :user_id
      )
      response.merge( { paid: true, amount_paid: 0, conference: @conference } )
    end
  end
end
