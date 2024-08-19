# app/models/concerns/media_attachable.rb
module MediaAttachable
  extend ActiveSupport::Concern

  included do
    has_many :media, as: :mediable, dependent: :destroy, class_name: 'Media'
  end

  # Find the requested media type or fallback to the default_image
  def image
    Media.find_or_default(self, 'image')
  end

  def video
    media.by_type('video').first
  end

  def default_image
    media.by_type('default_image').first
  end

  # Find all media for the record with media_types image or video
  def images_and_videos
    media.where(media_type: [Media.media_types[:image], Media.media_types[:video]])
  end

  def homepage_image
    Media.find_or_default(self, 'homepage_image')
  end

  def featured_homepage_image
    Media.find_or_default(self, 'featured_homepage_image')
  end

  def pos_image
    Media.find_or_default(self, 'pos_image')
  end
end

