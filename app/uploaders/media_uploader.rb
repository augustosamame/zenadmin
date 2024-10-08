require "image_processing/vips"

class MediaUploader < Shrine
  storages[:store] = Shrine.storages[:store_public]

  Attacher.default_url do |**options|
    "https://#{ENV['S3_AWS_STORAGE_BUCKET_NAME']}.s3.amazonaws.com/public/images/image_placeholder.png"
  end

  Attacher.validate do
    validate_max_size 5.megabytes, message: "is too large"
    validate_mime_type_inclusion [ "image/jpeg", "image/png", "image/gif" ]
  end

  Attacher.derivatives do |original|
    vips = ImageProcessing::Vips.source(original)

    {
      large:  vips.resize_to_limit!(400, 400),
      small:  vips.resize_to_limit!(200, 200),
      thumb:  vips.resize_to_limit!(50, 50)
    }
  end

  # Shrine::Attacher.promote_block do
  #  Shrine::PromoteJob.perform_async(self.class.name, record.class.name, record.id, name.to_s, file_data.to_json)
  # end

  # Shrine::Attacher.destroy_block do
  #  Shrine::DestroyJob.perform_async(self.class.name, data.to_json)
  # end

  # not using backgrounding here as were promoting manually in the after_commit of the media record. That is handled via a sidekiq job
end
