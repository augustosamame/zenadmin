# Load client-specific seed file based on environment variable or default
client_seed_file = "db//seeds_jardindelzen.rb"

if File.exist?(client_seed_file)
  puts "Loading seed data for client Sercam..."
  load client_seed_file
else
  puts "Warning: No seed file found at #{client_seed_file}"
end
