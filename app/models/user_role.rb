class UserRole < ApplicationRecord
  audited_if_enabled

  belongs_to :user
  belongs_to :role

  validates :user_id, uniqueness: { scope: :role_id, message: "can only have one of each role" }

  after_commit :create_customer_if_needed, on: :create

  private

    def create_customer_if_needed
      if role.name == "customer" && user.customer.nil?
        user.create_customer
      end
    end
end
