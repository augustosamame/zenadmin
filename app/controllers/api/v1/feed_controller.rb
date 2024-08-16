class Api::V1::FeedController < Api::V1::ApiBaseController

  def index
    UserActivity.create(user_id: current_user.id, activity_type: 'visit_feed')
    interested_in = current_user.gender == 'male' ? 'female' : 'male'
    #TODO change interested_in to be based on user preference (interested_in field in user model)
    @feed = User.where(gender: interested_in)
                .where(role: 'standard')
                .where(status: 'active')
                .where(inactivated_at: nil)
                .where.not(profile_image: nil)
                .where.not(id: current_user.id)
    
    @feed = @feed.where("age >= ?", params[:minAge]) if params[:minAge].present?
    @feed = @feed.where("age <= ?", params[:maxAge]) if params[:maxAge].present?

    if params[:sortBy] == 'newest'
      @feed = @feed.order(created_at: :desc)
    elsif params[:sortBy] == 'nearest' && current_user.latitude.present? && current_user.longitude.present?
      @feed = @feed.near([current_user.latitude, current_user.longitude], 100, order: :distance)
    elsif params[:sortBy] == 'recentlyActive'
      subquery = UserActivity.select("DISTINCT ON (user_id) user_id, created_at").order("user_id, created_at DESC").to_sql
      @feed = @feed.joins("JOIN (#{subquery}) latest_activities ON latest_activities.user_id = users.id").order(visual_priority: :desc).order("latest_activities.created_at DESC")
    else
      @feed = @feed.order("RANDOM()")
    end

    # Add pagination
    @feed = @feed.page(params[:page]).per(24)

    render json: Api::V1::FeedSerializer.new(@feed).serialized_json
  end

end