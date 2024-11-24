module Services
  module Sales
    class OrderCreditService
      def initialize(order)
        @order = order
        @credit_payment_method = PaymentMethod.find_by(name: "credit")
      end

      def evaluate_payment_status(operation: nil)
        return if @order.destroyed? || @order.marked_for_destruction?
        default_due_date_days = $global_settings[:default_credit_receivable_due_date] || 30

        ActiveRecord::Base.transaction do
          payments = @order.payments
          if payments.any?
            credit_payments = payments.where(payment_method: @credit_payment_method)
            non_credit_payments = payments.where.not(payment_method: @credit_payment_method)
            if credit_payments.any?
              paid_amount = non_credit_payments.sum(:amount_cents)
              if paid_amount > 0
                @order.update_columns(payment_status: :partially_paid, is_credit_sale: true)
              else
                @order.update_columns(payment_status: :unpaid, is_credit_sale: true)
              end
              create_credit_receivable if operation == :create
            else
              payment_amount = payments.sum(:amount_cents)
              if payment_amount >= @order.total_price_cents
                @order.update_columns(payment_status: :paid)
              else
                @order.update_columns(payment_status: :partially_paid, is_credit_sale: true)
              end
            end
          else
            @order.update_columns(payment_status: :unpaid, is_credit_sale: true)
            if operation == :create
              Payment.create!(
                payment_method: @credit_payment_method,
                cashier_shift: @order.cashier_shift,
                user: @order.user,
                payable: @order,
                amount_cents: @order.total_price_cents,
                currency: @order.currency,
                due_date: @order.created_at + default_due_date_days.days
              )
              create_credit_receivable
            end
          end
          @order.order_is_paid_activities if @order.paid?
        end
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Failed to process order credit: #{e.message}"
        raise e
      end

      def create_credit_receivable
        default_due_date_days = $global_settings[:default_credit_receivable_due_date] || 30

        ActiveRecord::Base.transaction do
          @order.payments.each do |payment|
            if payment.payment_method == @credit_payment_method
              AccountReceivable.create!(
                user: @order.user,
                order: @order,
                payment: payment,
                amount_cents: payment.amount_cents,
                currency: payment.currency,
                due_date: payment.due_date || payment.created_at + default_due_date_days.days
              )
              due_date = payment.due_date || (payment.created_at + default_due_date_days.days)
              payment.update_column(:due_date, due_date)
            else
              receivable = AccountReceivable.create!(
                user: @order.user,
                order: @order,
                payment: payment,
                amount_cents: payment.amount_cents,
                currency: payment.currency,
                due_date: @order.created_at,
                status: "paid"
              )
              payment.update_column(:account_receivable_id, receivable.id)
              AccountReceivablePayment.create!(
                account_receivable: receivable,
                payment: payment,
                amount_cents: payment.amount_cents,
                currency: payment.currency
              )
            end
          end
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "Failed to create credit receivable: #{e.message}"
          raise e
        end
      end
    end
  end
end
