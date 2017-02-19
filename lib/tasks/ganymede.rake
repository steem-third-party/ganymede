namespace :ganymede do
  desc "display the current environment of rake"
  task :current_environment do
    puts "You are running rake task in #{Rails.env} environment"
  end
end