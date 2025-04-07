class Transportista < ApplicationRecord
  self.table_name = "transportistas"

  enum :transportista_type, {
    publico: 0,
    privado: 1
  }

  enum :doc_type, {
    dni: 0,
    ruc: 1
  }

  enum :status, {
    active: 0,
    inactive: 1
  }

  validates :transportista_type, presence: true
  validates :doc_type, presence: true
  validates :status, presence: true

  validates :ruc_number, presence: true, if: -> { ruc? }
  validates :razon_social, presence: true, if: -> { ruc? }

  validates :first_name, presence: true, if: -> { dni? }
  validates :last_name, presence: true, if: -> { dni? }
  validates :dni_number, presence: true, if: -> { dni? }
  validates :license_number, presence: true, if: -> { dni? }
end
