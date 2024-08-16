class Api::V1::S3PresignerController < Api::V1::ApiBaseController
  def presign
    object_key = "uploads/user_media/#{params[:user_uuid]}/#{params[:filename]}"
    presigned_url = Services::AwsS3.new.generate_presigned_url(object_key, params[:mimetype])

    render json: { url: presigned_url }
  end
end
