class StaticController < ApplicationController
  def index
  end
  
  def favicon
    favicon = File.open "#{Rails.root}/app/assets/images/ganymede.svg"
    
    send_file favicon, type: 'image/svg', disposition: 'inline'
  end
  
  def mvests
    render plain: MvestsLookupJob.new.perform
  end
end
