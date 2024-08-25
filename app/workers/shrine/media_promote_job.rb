class Shrine::MediaPromoteJob
  include Sidekiq::Worker

  def perform(media_id)
    media = Media.find(media_id)
    if media.file_attacher.cached?
      media.file_attacher.promote
      media.update_columns(
        file_data: media.file_data,
      ) # Update the file_data without triggering callbacks
    end
  end

end