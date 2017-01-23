module ApplicationHelper
  INITIAL_TIMEOUT = 2
  MAX_TIMEOUT = case Rails.env
    when 'test' then 0
    when 'development' then 4
    else 15
    end

  def site_logo
    ENV['SITE_LOGO'] || 'https://i.imgur.com/uCaoQzf.png'
  end
  
  def site_prefix
    ENV['SITE_PREFIX'] || 'http://steemit.com'
  end

  def api_url
    ENV['API_URL'] || 'https://node.steem.ws:443'
  end

  def fallback_api_url
    ENV['FALLBACK_API_URL'] || 'https://this.piston.rocks:443'
  end

  def api(url = api_url)
    @api ||= Radiator::Api.new(url: url)
  end
  
  def follow_api(url = api_url)
    @follow_api ||= Radiator::FollowApi.new(url: url)
  end
  
  def timeout(exception = nil)
    @timeout ||= INITIAL_TIMEOUT
    raise exception if @timeout > MAX_TIMEOUT
    
    sleep(@timeout += 2)
  end
  
  def api_execute (m, *options)
    response = nil
    
    loop do
      begin
        response = api.send(m, *options)
        break if !!response
      rescue => e
        Rails.logger.warn "Radiator::Api falling back to: #{fallback_api_url}"
        @api = nil
        api(fallback_api_url)
        timeout e
      end
    end
    
    response
  end
  
  def follow_api_execute (m, *options)
    response = nil
    
    loop do
      begin
        response = follow_api.send(m, *options)
        break if !!response
      rescue
        Rails.logger.warn "Radiator::FollowApi Falling back to: #{fallback_api_url}"
        @follow_api = nil
        follow_api(fallback_api_url)
        timeout
      end
    end
    
    response
  end
  
  def mvests
    feed_history = api_execute(:get_feed_history).result
    steem_per_mvest = api_execute(:steem_per_mvest)

    current_median_history = feed_history.current_median_history
    base = current_median_history.base
    base = base.split(' ').first.to_f
    quote = current_median_history.quote
    quote = quote.split(' ').first.to_f

    steem_per_usd = (base / quote) * steem_per_mvest

    # E.g. from 2016/11/25: 1 MV = 1M VESTS = 459.680 STEEM = $50.147
    "1 MV = 1M VESTS = #{("%.3f" % steem_per_mvest)} STEEM = $#{("%.3f" % steem_per_usd)}"
  end
end
