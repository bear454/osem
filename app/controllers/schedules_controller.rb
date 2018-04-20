# frozen_string_literal: true

class SchedulesController < ApplicationController
  load_and_authorize_resource
  protect_from_forgery with: :null_session
  before_action :respond_to_options
  load_resource :conference, find_by: :short_title
  load_resource :program, through: :conference, singleton: true, except: :index
  before_action :load_withdrawn_event_schedules, only: [:show, :events]

  def show
    respond_to do |format|
      format.html {
        @rooms = @conference.venue.rooms if @conference.venue
        schedules = @program.selected_event_schedules
        unless schedules
          redirect_to events_conference_schedule_path(@conference.short_title)
        end

        @dates = @conference.start_date..@conference.end_date
        @step_minutes = @program.schedule_interval.minutes
        @conf_start = @conference.start_hour
        @conf_period = @conference.end_hour - @conf_start

        # the schedule takes you to today if it is a date of the schedule
        @current_day = @conference.current_conference_day
        @day = @current_day.present? ? @current_day : @dates.first
        if @current_day
          # the schedule takes you to the current time if it is beetween the start and the end time.
          @hour_column = @conference.hours_from_start_time(@conf_start, @conference.end_hour)
        end
        # Ids of the schedules of confrmed self_organized tracks along with the selected_schedule_id
        @selected_schedules_ids = [@conference.program.selected_schedule_id]
        @conference.program.tracks.self_organized.confirmed.each do |track|
          @selected_schedules_ids << track.selected_schedule_id
        end
        @selected_schedules_ids.compact!
      }
      format.xml {
        @events_xml = Event.eager_load(:difficulty_level, :track, :event_type, event_schedules: :room, event_users: :user).where(event_schedules: {schedule: @program.selected_schedule}).group_by{|e| e.event_schedules.first.start_time.to_date}
      }
    end
  end

  def events
    @dates = @conference.start_date..@conference.end_date

    @events_schedules = @program.selected_event_schedules

    @unscheduled_events = @program.events.confirmed.eager_load(:speakers).order('users.name ASC') - @events_schedules.map(&:event)

    day = @conference.current_conference_day
    @tag = day.strftime('%Y-%m-%d') if day
  end

  def kiosk
    if Rails.env.development?
      current_datetime = DateTime.parse("2018-04-28 10:00 PDST")
    else
      current_datetime = DateTime.now
    end
    event_schedules = @program.selected_event_schedules.sort_by! do |event_schedule|
      [ event_schedule.start_time, event_schedule.room.name ]
    end
    @now_event_schedules = event_schedules.select do |event_schedule|
      event_schedule.start_time <= current_datetime &&
      event_schedule.end_time >= current_datetime
    end
    @next_event_schedules = event_schedules.select do |event_schedule|
      event_schedule.start_time > current_datetime
    end[0..19]
    render layout: 'kiosk'
  end

  private

  def respond_to_options
    respond_to do |format|
      format.html { head :ok }
    end if request.options?
  end

  def load_withdrawn_event_schedules
    # Avoid making repetitive EXISTS queries for these later.
    # See usage in EventsHelper#canceled_replacement_event_label
    @withdrawn_event_schedules = EventSchedule.withdrawn_or_canceled_event_schedules(@program.schedule_ids)
  end
end
