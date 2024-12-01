class Customer < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  belongs_to :user
  include MediaUploader::Attachment(:avatar)

  enum :doc_type, { dni: 1, ce: 4, passport: 7 }
  translate_enum :doc_type

  before_validation :set_consumer_password, on: :create
  before_validation :set_consumer_email, on: :create
  after_commit :set_consumer_role_to_user, on: :create

  # validates :doc_id, presence: true, uniqueness: true

  def set_consumer_role_to_user
    user.add_role("customer")
  end

  def customer_name
    self.user.name.present? ? self.user.name : self.factura_razon_social
  end

  private

  def set_consumer_email
    if self.doc_id.present?
      user.email = "#{self.doc_id}@sincorreo.com"
    elsif self.factura_ruc.present?
      user.email = "#{self.factura_ruc}@sincorreo.com"
    end
  end

  def set_consumer_password
    user.password = SecureRandom.alphanumeric(8) unless user.password.present?
  end
end
