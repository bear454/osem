# frozen_string_literal: true

module Admin
  class RegistrationsController < Admin::BaseController
    load_and_authorize_resource :conference, find_by: :short_title
    load_and_authorize_resource :registration, through: :conference
    before_action :set_user, except: [:index]

    def index
      authorize! :show, Registration.new(conference_id: @conference.id)
      @registrations = @conference.registrations.eager_load(
        :qanswers, user: :roles
      ).order('registrations.created_at ASC').to_a
      @attended = @registrations.count(&:attended)
      @questions = @conference.questions.to_a
      @ticket = @conference.tickets.where(registration_ticket: true).first

      @registration_distribution = @conference.registration_distribution
      @affiliation_distribution = @conference.affiliation_distribution
      @code_of_conduct = @conference.code_of_conduct.present?

      @pdf_filename = "#{@conference.title}.pdf"
    end

    def new
      # Redirect to registration edit when user is already registered
      if @conference.user_registered?(@user)
        # Authorization needs to happen in every action before the return statement
        # We authorize the #edit action, since we redirect to it
        @registration = @user.registrations.find_by(conference_id: @conference.id)
        authorize! :edit, @registration
        redirect_to edit_admin_conference_registration_path(@conference, @registration)
      end
      @registration = @conference.registrations.new(user: @user)
    end

    def create
      @user.update_attributes(user_params)
      @conference.registrations.new(registration_params)

      if @registration.save
        redirect_to admin_conference_registrations_path(@conference),
          notice: "#{@user.name} is now registered for #{@conference.title}."
      else
        redirect_back fallback_location: admin_conference_registrations_path(@conference),
          error: "#{@user.name} was not registered to #{@conference.title}: #{@registration.errors.full_messages.to_sentence}"
      end
    end

    def edit; end

    def update
      @user.update_attributes(user_params)

      @registration.update_attributes(registration_params)
      if @registration.save
        redirect_to admin_conference_registrations_path(@conference.short_title),
                    notice: "Successfully updated registration for #{@registration.user.email}!"
      else
        flash.now[:error] = "An error prohibited the Registration for #{@registration.user.email}: "\
                        "#{@registration.errors.full_messages.join('. ')}."
        render :edit
      end
    end

    def destroy
      if can? :destroy, @registration
        @registration.destroy
        redirect_to admin_conference_registrations_path(@conference.short_title),
                    notice: "Deleted registration for #{@user.name}!"
      else
        redirect_to admin_conference_registrations_path(@conference.short_title),
                    error: 'You must be an admin to delete a registration.'
      end
    end

    def toggle_attendance
      @registration.attended = !@registration.attended
      if @registration.save
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def toggle_code_of_conduct
      @registration.accepted_code_of_conduct = !@registration.accepted_code_of_conduct
      if @registration.save
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find_by(id: params['user_id'] || @registration.user_id )
    end

    def user_params
      params.require(:user).permit(:name, :nickname, :affiliation)
    end

    def registration_params
      params.require(:registration).permit(
        :user_id, :conference_id, :arrival, :departure, :attended,
        :volunteer, :other_special_needs, :accepted_code_of_conduct,
        vchoice_ids: [], qanswer_ids: [], qanswers_attributes: [], event_ids: []
      )
    end
  end
end
