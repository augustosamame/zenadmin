namespace :db do
  desc "Truncate all tables"
  task truncate_all: :environment do
    ActiveRecord::Base.connection.tables.each do |table|
      ActiveRecord::Base.connection.execute("TRUNCATE #{table} RESTART IDENTITY CASCADE") unless table == "schema_migrations"
    end
    puts "All tables truncated and primary keys reset."
  end

  desc "Drop, create, and migrate the database"
  task nukedb: :environment do
    # Disconnect from the database
    ActiveRecord::Base.connection_pool.disconnect!

    # Get the current database name
    config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first
    database_name = config.database

    # Run the kill_connection script
    system("zsh -c '~/scripts/kill_connections.sh #{database_name}'")

    # Small delay to ensure connections are fully closed
    sleep 1

    # Drop the database without using ActiveRecord
    config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).first
    system("dropdb #{database_name}")

    # Create and migrate the database
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke

    puts "Database dropped, created, and migrated successfully."
  end
end
