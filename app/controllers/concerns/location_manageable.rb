module LocationManageable
  extend ActiveSupport::Concern

  included do
    before_action :set_location_variables
    class_attribute :location_required_actions, default: []
  end

  class_methods do
    def requires_location_selection(*actions)
      self.location_required_actions += actions.map(&:to_s)
    end
  end

  private

  def set_location_variables
    @locations = available_locations
    @current_location = determine_current_location
    session[:current_location_id] = @current_location&.id

    # Force location selection if current action requires it
    if requires_location_for_current_action?
      @current_location ||= Location.find_by(id: current_user&.location_id) || Location.first
      session[:current_location_id] = @current_location.id
    end
  end

  def requires_location_for_current_action?
    self.class.location_required_actions.include?(action_name)
  end

  def available_locations
    if current_user&.any_admin_or_supervisor?
      Location.active.order(:name)
    else
      Location.active.where(id: current_user&.location_id)
    end
  end

  def determine_current_location
    location_id = params[:location_id] || session[:current_location_id]

    if current_user&.any_admin_or_supervisor?
      return nil if location_id.blank?
      Location.find_by(id: location_id)
    else
      Location.find_by(id: current_user&.location_id)
    end
  end
end
