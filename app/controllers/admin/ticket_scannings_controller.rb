# frozen_string_literal: true

module Admin
  class TicketScanningsController < Admin::BaseController
    before_action :authenticate_user!
    authorize_resource

    def index; end

    def create
      @ticket_scanning = TicketScanning.new(ticket_scanning_params)
      @ticket_scanning.save
      redirect_to admin_ticket_scannings_path,
        notice: "Ticket with token #{@ticket_scanning.physical_ticket.token} successfully scanned."
    end

    def new
      @physical_ticket = PhysicalTicket.find_by_token(params['token'])
      @ticket_scanning = TicketScanning.new(physical_ticket: @physical_ticket)
    end

    private

    def ticket_scanning_params
      params.require(:ticket_scanning).permit(:physical_ticket_id)
    end
  end
end
