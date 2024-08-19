module ApplicationHelper
  def draft_order_present?
    session[:draft_order].present?
  end
end
