Rails.application.config.assets.version = "1.0"

Rails.application.config.assets.paths << Rails.root.join("app", "assets", "audios", "builds")

Rails.application.config.assets.precompile += %w[ notification_feed_alert.mp3 ]

Rails.application.config.assets.precompile += %w[ application.js application.css ]
