class Customer < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  belongs_to :user
  include MediaUploader::Attachment(:avatar)

  enum :doc_type, { dni: 0, ce: 1, passport: 2, other: 3 }
  translate_enum :doc_type

  before_validation :set_consumer_password, on: :create
  after_commit :set_consumer_role_to_user, on: :create

  validates :doc_id, presence: true, uniqueness: true

  def set_consumer_role_to_user
    user.add_role("customer")
  end

  private

  def set_consumer_password
    user.password = SecureRandom.alphanumeric(8) unless user.password.present?
  end
end
