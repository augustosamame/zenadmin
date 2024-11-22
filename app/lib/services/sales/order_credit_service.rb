module Services
  module Sales
    class OrderCreditService
      def initialize(order)
        @order = order
        @credit_payment_method = PaymentMethod.find_by(name: "credit")
      end

      def reevaluate_payment_status
        payments = @order.payments
        if payments.any?
          credit_payments = payments.where(payment_method: @credit_payment_method)
          non_credit_payments = payments.where.not(payment_method: @credit_payment_method)
          if credit_payments.any?
            paid_amount = non_credit_payments.sum(:amount_cents)
            if paid_amount > 0
              @order.update_columns(payment_status: :partially_paid)
            else
              @order.update_columns(payment_status: :unpaid)
            end
            create_credit_receivable
          else
            payment_amount = payments.sum(:amount_cents)
            if payment_amount >= @order.total_price_cents
              @order.update_columns(payment_status: :paid)
            else
              @order.update_columns(payment_status: :partially_paid)
            end
          end
        else
          @order.update(payment_status: :unpaid)
        end
        @order.order_is_paid_activities if @order.paid?
      end

      def create_credit_receivable
        default_due_date_days = $global_settings[:default_credit_receivable_due_date] || 30
        @order.payments.where(payment_method: @credit_payment_method).each do |payment|
          AccountReceivable.create(
            user: @order.user,
            order: @order,
            payment: payment,
            amount_cents: payment.amount_cents,
            currency: payment.currency,
            due_date: payment.due_date || payment.created_at + default_due_date_days.days
          )
        end
      end
    end
  end
end
