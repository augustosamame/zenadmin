export const resourceMappings = {
  LoyaltyTier: {
    buttonText: "Crear Rangos de Loyalty",
    buttonUrl: "/admin/loyalty_tiers/new",
    ajaxUrl: "/admin/loyalty_tiers.json"
  },
  Product: {
    buttonText: "Crear Producto",
    buttonUrl: "/admin/products/new",
    ajaxUrl: "/admin/products.json"
  },
  PeriodicInventory: {
    buttonText: "Crear Inventario Físico",
    buttonUrl: "/admin/inventory/periodic_inventories/new",
    ajaxUrl: "/admin/inventory/periodic_inventories.json"
  },
  CashierShift: {
    buttonText: "Crear Turno de Caja",
    buttonUrl: "/admin/cashier_shifts/new",
    ajaxUrl: "/admin/cashier_shifts.json"
  },
  ComboProduct: {
    buttonText: "Crear Combo de Productos",
    buttonUrl: "/admin/combo_products/new",
    ajaxUrl: "/admin/combo_products.json"
  },
  CommissionRange: {
    buttonText: "Crear Rango de Comisiones",
    buttonUrl: "/admin/commission_ranges/new",
    ajaxUrl: "/admin/commission_ranges.json"
  },
  Commission: {
    buttonText: "Crear Comisión",
    buttonUrl: "/admin/commissions/new",
    ajaxUrl: "/admin/commissions.json"
  },
  Customer: {
    buttonText: "Crear Cliente",
    buttonUrl: "/admin/customers/new",
    ajaxUrl: "/admin/customers.json"
  },
  InTransitStock: {
    buttonText: "Crear Transito de Stock",
    buttonUrl: "/admin/in_transit_stocks/new",
    ajaxUrl: "/admin/in_transit_stocks.json"
  },
  Location: {
    buttonText: "Crear Tienda",
    buttonUrl: "/admin/locations/new",
    ajaxUrl: "/admin/locations.json"
  },
  Order: {
    buttonText: "Crear Venta",
    buttonUrl: "/admin/orders/new",
    ajaxUrl: "/admin/orders.json"
  },
  PaymentMethod: {
    buttonText: "Crear Método de Pago",
    buttonUrl: "/admin/payment_methods/new",
    ajaxUrl: "/admin/payment_methods.json"
  },
  StockTransfer: {
    buttonText: "Crear Transferencia de Stock",
    buttonUrl: "/admin/stock_transfers/new",
    ajaxUrl: "/admin/stock_transfers.json"
  },
  StockAdjustment: {
    buttonText: "Crear Ajuste de Inventario",
    buttonUrl: "/admin/stock_transfers/new",
    buttonParams: {
      stock_adjustment: true
    },
    ajaxUrl: "/admin/stock_transfers.json"
  },
  User: {
    buttonText: "Crear Usuario",
    buttonUrl: "/admin/users/new",
    ajaxUrl: "/admin/users.json"
  },
  SellerBiweeklySalesTarget: {
    buttonText: "Crear Meta de Ventas Quincenal",
    buttonUrl: "/admin/seller_biweekly_sales_targets/new",
    ajaxUrl: "/admin/seller_biweekly_sales_targets.json"
  },
  Requisition: {
    buttonText: "Crear Pedido",
    buttonUrl: "/admin/requisitions/new",
    ajaxUrl: "/admin/requisitions.json"
  },
  UserAttendanceLog: {
    buttonText: "Crear Checkin / Checkout",
    buttonUrl: "/admin/user_attendance_logs/new",
    ajaxUrl: "/admin/user_attendance_logs.json"
  },
  Tag: {
    buttonText: "Crear Etiqueta",
    buttonUrl: "/admin/tags/new",
    ajaxUrl: "/admin/tags.json"
  },
  ProductCategory: {
    buttonText: "Crear Categoría",
    buttonUrl: "/admin/product_categories/new",
    ajaxUrl: "/admin/product_categories.json"
  },
  Discount: {
    buttonText: "Crear Descuento",
    buttonUrl: "/admin/discounts/new",
    ajaxUrl: "/admin/discounts.json"
  },
  ProductPack: {
    buttonText: "Crear Pack de Productos",
    buttonUrl: "/admin/product_packs/new",
    ajaxUrl: "/admin/product_packs.json"
  },
  Payment: {
    buttonText: "Crear Pago",
    buttonUrl: "/admin/payments/new",
    ajaxUrl: "/admin/payments.json"
  },
  AccountReceivable: {
    buttonText: "Crear Cuenta por Cobrar",
    buttonUrl: "/admin/account_receivables/new",
    ajaxUrl: "/admin/account_receivables.json"
  },
  ConsolidatedSales: {
    buttonText: "Exportar", // or null if you don't want a create button
    buttonUrl: "/admin/consolidated_sales/new", // or null if you don't want a create button
    ajaxUrl: "/admin/consolidated_sales.json"
  },
  OrdersPerProduct: {
    ajaxUrl: "/admin/orders_per_product.json"
  },
  PriceList: {
    buttonText: "Crear Lista de Precios",
    buttonUrl: "/admin/price_lists/new",
    ajaxUrl: "/admin/price_lists.json"
  },
  PriceListItem: {
    search_input: true,
    paging: true,
    info: true,
    page_length: 10
  }
}
