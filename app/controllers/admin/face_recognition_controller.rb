require "aws-sdk-rekognition"

class Admin::FaceRecognitionController < Admin::AdminController
  skip_before_action :verify_authenticity_token

  def recognize
    client = Aws::Rekognition::Client.new
    photo_data = params[:image].split(",")[1] # Remove data URL prefix
    image_bytes = Base64.decode64(photo_data)

    response = client.search_faces_by_image({
      collection_id: "sellers_faces",
      image: { bytes: image_bytes },
      max_faces: 1, # Limit to 1 match
      face_match_threshold: 95 # Confidence threshold
    })

    if response.face_matches.any?
      matched_user_id = response.face_matches.first.face.external_image_id
      @user = User.find(matched_user_id)

      render json: { match: true, user: @user }
    else
      render json: { match: false }
    end
  end
end
