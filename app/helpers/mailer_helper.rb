module MailerHelper
  def spacer(height)
    content_tag(:div, "", style: "margin: #{height}px 0;")
  end
end
