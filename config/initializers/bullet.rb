if defined? Bullet
  Bullet.add_safelist(type: :unused_eager_loading, class_name: "CashierShift", association: :cashier)
  Bullet.add_safelist(type: :unused_eager_loading, class_name: "Discount", association: :discount_filters)
  #Bullet.raise = true
end
