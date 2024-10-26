class UserSellerPhoto < ApplicationRecord
  belongs_to :user

  validates :seller_photo, presence: true
end
