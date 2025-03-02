class Customer < ApplicationRecord
  audited_if_enabled
  include TranslateEnum

  belongs_to :user
  belongs_to :price_list, optional: true
  include MediaUploader::Attachment(:avatar)

  enum :doc_type, { dni: 1, ce: 4, passport: 7 }
  translate_enum :doc_type

  before_validation :set_consumer_password, on: :create
  before_validation :set_consumer_email, on: :create
  after_commit :set_consumer_role_to_user, on: :create

  # validates :doc_id, presence: true, uniqueness: true

  # RUC validations
  validates :factura_ruc, format: {
    with: /\A\d{11}\z/,
    message: "debe tener exactamente 11 dígitos"
  }, if: -> { factura_ruc.present? }

  validates :factura_razon_social, presence: {
    message: "no puede estar en blanco si RUC está presente"
  }, if: -> { factura_ruc.present? }

  # DNI validation - must be either blank or exactly 8 digits for DNI type
  validates :doc_id, format: {
    with: /\A\d{8}\z/,
    message: "debe tener exactamente 8 dígitos"
  }, if: -> { doc_type == "dni" && doc_id.present? && doc_id.strip != "" }

  # At least one identifier must be present
  validate :must_have_one_identifier
  validate :first_name_or_last_name_present_if_dni

  def first_name_or_last_name_present_if_dni
    if doc_type == "dni" && doc_id.present? && (self.user.first_name.blank? || self.user.last_name.blank?)
      errors.add(:base, "El nombre y apellido son obligatorios si se proporciona un DNI. NO PRESIONAR ENTER luego de ingresar el DNI, esperar a que se complete el formulario con los datos desde RENIEC")
    end
  end

  def set_consumer_role_to_user
    user.add_role("customer")
  end

  def customer_name
    self.user.name.present? ? self.user.name : self.factura_razon_social
  end

  private

  def must_have_one_identifier
    if doc_id.blank? && factura_ruc.blank?
      errors.add(:base, "Debe proporcionar al menos un documento de identidad (DNI/CE/Pasaporte) o RUC")
    end
  end

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
