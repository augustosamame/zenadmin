class Media < ApplicationRecord
  belongs_to :mediable, polymorphic: true

  enum :media_type, {
    default_image: 0,
    image: 1,
    video: 2,
    pos_image: 5,
    homepage_image: 4,
    featured_homepage_image: 5,
    # Add more media types as needed
  }

  validates :file_path, presence: true
  validates :media_type, presence: true

  scope :by_type, ->(type) { where(media_type: media_types[type]) }
  scope :ordered, -> { order(:position) }

  # Find the requested media type or fallback to the default_image
  def self.find_or_default(mediable, media_type)
    media = mediable.media.by_type(media_type).first
    media || mediable.media.by_type(:default_image).first
  end
  
end