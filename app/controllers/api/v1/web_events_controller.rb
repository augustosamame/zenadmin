class Api::V1::WebEventsController < Api::V1::ApiBaseController
  protect_from_forgery with: :null_session, only: [ :create, :contact_us ]
  skip_before_action :verify_authenticity_token, only: [ :create, :contact_us ]
  skip_before_action :authenticate_user_with_token, only: [ :create, :contact_us ]

  def contact_us
    @web_event = WebEvent.new(
      event_name: "landing_page_contact_us",
      event_data: { name: params[:name], contact: params[:contact], message: params[:message] }.to_json
    )
    if @web_event.save
      Services::LabsMobileSms.new.send_sms_to_number_no_worker(@web_event.event_data, "51986976377")
      render json: @web_event, status: :created
    else
      render json: @web_event.errors, status: :unprocessable_entity
    end
  end

  def create
    case params[:event_name]
    when "prospect_landing_page_view"
      prospect_id = params[:event_data]["prospect_id"]
      prospect = Prospect.find_by(id: prospect_id)
      if prospect
        if prospect.status == "status_new" || prospect.status == "status_contacted"
          prospect.update(status: "status_clicked")
        end
        if prospect.activities_from_tracking_pixel.present?
          current_activities = prospect.activities_from_tracking_pixel&.deep_stringify_keys || {}
          current_activities["prospect_landing_page_view"] ||= []
          current_activities["prospect_landing_page_view"] << Time.current.iso8601

          prospect.update(activities_from_tracking_pixel: current_activities)
        else
          prospect.update(activities_from_tracking_pixel: { prospect_landing_page_view: [ Time.current.iso8601 ] })
        end
      else
        render json: "Not found", status: :unprocessable_entity and return
      end
    when "click"
      # Do something
    else
      raise "Unknown event_name: #{params[:event_name]}"
    end

    @web_event = WebEvent.new(
      event_name: params[:event_name],
      event_data: params[:event_data],
      prospect_id: params[:event_data][:prospect_id],
      user_id: params[:event_data][:user_id]
    )
    if @web_event.save
      render json: @web_event, status: :created
    else
      render json: @web_event.errors, status: :unprocessable_entity
    end
  end
end
