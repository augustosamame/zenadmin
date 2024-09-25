Rails.application.config.assets.version = "1.0"

Rails.application.config.assets.paths << Rails.root.join("app", "node_modules", "audios")

Rails.application.config.assets.precompile += %w[ notification_feed_alert.mp3 application.tailwind.css ]
