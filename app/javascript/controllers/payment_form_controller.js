import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["userSelect", "orderSelect"]

  async userChanged(event) {
    const userId = event.target.value
    const orderSelect = this.orderSelectTarget

    if (!userId) {
      orderSelect.innerHTML = '<option value="">Seleccione venta</option>'
      return
    }

    try {
      const response = await fetch(`/admin/users/${userId}/unpaid_orders`)
      const orders = await response.json()

      // Update the select element
      orderSelect.innerHTML = '<option value="">Seleccione venta</option>'

      orders.forEach(order => {
        const option = new Option(
          `${order.custom_id} - ${order.user_name} - ${order.formatted_price}`,
          order.id
        )
        orderSelect.add(option)
      })

    } catch (error) {
      console.error("Error fetching orders:", error)
    }
  }
}