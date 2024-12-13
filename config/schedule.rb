set :chronic_options, hours24: true
set :timezone, "America/Lima"
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end
#
every :sunday, at: "9am" do # Use any day of the week or :weekend, :weekday
  runner "Services::Inventory::AutomaticRequisitionsService.create_weekly_requisitions"
end

every :day, at: "8am" do
  runner "Services::Sales::LoyaltyTierService.update_all_users_loyalty_tiers"
end

every :hour do
  runner "ProductPack.toggle_status_based_on_datetime"
end

every :hour do
  runner "Discount.toggle_status_based_on_datetime"
end

every :day, at: "2am" do
  runner "CashierShift.automatic_close_all_shifts"
end

# Learn more: http://github.com/javan/whenever
