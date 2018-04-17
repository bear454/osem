# frozen_string_literal: true

class TicketScanning < ApplicationRecord
  belongs_to :physical_ticket

  serialize :materials

  before_create :mark_user_present, :clean_materials

  private

  def mark_user_present
    if physical_ticket.ticket.registration_ticket?
      physical_ticket.user.mark_attendance_for_conference(physical_ticket.conference)
    end
  end

  def clean_materials
    return if materials.blank?
    materials.delete_if(&:blank?)
  end
end
