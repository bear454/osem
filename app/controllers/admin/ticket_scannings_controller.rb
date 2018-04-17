# frozen_string_literal: true

module Admin
  class TicketScanningsController < Admin::BaseController
    before_action :authenticate_user!
    authorize_resource

    def index;
      @conferences = Conference.upcoming
    end

    def create
      @ticket_scanning = TicketScanning.new(ticket_scanning_params)
      @ticket_scanning.save
      redirect_to admin_ticket_scannings_path,
        notice: "Ticket with token #{@ticket_scanning.physical_ticket.token} successfully scanned."
    end

    def new
      @physical_ticket = PhysicalTicket.eager_load(
        :user, :ticket_scannings, :conference
      ).find_by_token(params['token'])
      @attendee = @physical_ticket.user
      @scans = @physical_ticket.ticket_scannings
      @conference = @physical_ticket.conference
      @registration = @attendee.registrations.for_conference(@conference)
      @qanswers = @registration.qanswers.eager_load(:question, :answer)
      @purchases = @attendee.ticket_purchases.by_conference(@conference).eager_load(:ticket)
      @materials = @purchases.collect { |p| (p.ticket.materials || []) * p.quantity }.flatten.compact.sort
      @delivered = @scans.collect(&:materials).flatten.compact.sort
      @delivered.each do |delivered|
        index = @materials.index(delivered)
        @materials.delete_at(index) if index
      end

      @ticket_scanning = TicketScanning.new(physical_ticket: @physical_ticket)
    end

    private

    def ticket_scanning_params
      params.require(:ticket_scanning).permit(
        :physical_ticket_id,
        materials: []
      )
    end
  end
end
