class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :api, :follow_api
  helper_method :get_discussions_by_trending

  INITIAL_TIMEOUT = 2
  MAX_TIMEOUT = 300
private
  def api
    @@API ||= Radiator::Api.new(url: 'https://node.steem.ws:443')
  end
  
  def follow_api
    @@FOLLOW_API ||= Radiator::FollowApi.new(url: 'https://node.steem.ws:443')
  end
  
  def timeout
    @timeout ||= INITIAL_TIMEOUT
    @timeout = INITIAL_TIMEOUT if @timeout > MAX_TIMEOUT
    
    sleep(@timeout += 2)
  end
  
  def api_execute (m, *options)
    response = nil
    
    loop do
      begin
        response = api.send(m, *options)
        break if !!response
      rescue
        timeout
      end
    end
    
    response
  end
end
