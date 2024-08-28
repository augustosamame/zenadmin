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
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    puts "Database dropped, created, and migrated successfully."
  end
end
