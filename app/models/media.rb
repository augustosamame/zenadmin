class Media < ApplicationRecord
  audited_if_enabled
  include TranslateEnum
  belongs_to :mediable, polymorphic: true
  include MediaUploader::Attachment(:file)

  enum :media_type, {
    default_image: 0,
    image: 1,
    video: 2,
    pos_image: 5,
    homepage_image: 4,
    featured_homepage_image: 5
    # Add more media types as needed
  }
  translate_enum :media_type

  validates :file, presence: true

  scope :by_type, ->(type) { where(media_type: media_types[type]) }
  scope :ordered, -> { order(:position) }

  after_commit :promote_from_cache

  def promote_from_cache
    Shrine::MediaPromoteJob.perform_async(self.id)
  end

  # Find the requested media type or fallback to the default_image
  def self.find_or_default(mediable, media_type)
    media = mediable.media.by_type(media_type).first
    media || mediable.media.by_type(:default_image).first
  end

  def smart_image(size)
    if self.file_attacher.derivatives.empty?
      self.file_url
    else
      self.file_url(size)
    end
  end
end
