if defined? Bullet
  Bullet.add_safelist(type: :unused_eager_loading, class_name: "CashierShift", association: :cashier)
end
