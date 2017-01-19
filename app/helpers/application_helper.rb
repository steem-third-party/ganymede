module ApplicationHelper
  INITIAL_TIMEOUT = 2
  MAX_TIMEOUT = 300

  def site_prefix
    ENV['SITE_PREFIX'] || 'http://steemit.com'
  end

  def api_url
    ENV['API_URL'] || 'https://node.steem.ws:443'
  end

  def api
    @@API ||= Radiator::Api.new(url: api_url)
  end
  
  def follow_api
    @@FOLLOW_API ||= Radiator::FollowApi.new(url: api_url)
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
