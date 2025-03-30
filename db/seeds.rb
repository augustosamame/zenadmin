# Load client-specific seed file based on environment variable or default
case ENV["CURRENT_ORGANIZATION"]
when "jardindelzen"
  client_seed_file = "db/seeds_jardindelzen.rb"
when "sercam"
  client_seed_file = "db/seeds_sercam.rb"
when "constructor"
  client_seed_file = "db/seeds_elconstructor.rb"
end

if File.exist?(client_seed_file)
  puts "Loading seed data for client #{ENV["CURRENT_ORGANIZATION"]}..."
  load client_seed_file
else
  puts "Warning: No seed file found at #{client_seed_file}"
end
