class Customer < ApplicationRecord
  belongs_to :user
  include MediaUploader::Attachment(:avatar)

  enum :doc_type, { dni: 0, ce: 1, passport: 2, other: 3 }

  after_commit :set_consumer_role_to_user, on: :create

  def set_consumer_role_to_user
    user.add_role("customer")
  end

  private
end