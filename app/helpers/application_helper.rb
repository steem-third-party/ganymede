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
  
  def rshares_json_url
    ENV['RSHARES_JSON_URL'] || 'https://steemdb.com/api/rshares'
  end

  def downvotes_json_url
    ENV['DOWNVOTES_JSON_URL'] || 'https://steemdb.com/api/downvotes'
  end

  def api(url = api_url)
    @api ||= Radiator::Api.new(url: url)
  end
  
  def follow_api(url = api_url)
    @follow_api ||= Radiator::FollowApi.new(url: url)
  end
  
  def timeout(exception = nil)
    @timeout ||= INITIAL_TIMEOUT
    raise exception || "Timeout Reached: #{@timeout} > #{MAX_TIMEOUT}" if @timeout > MAX_TIMEOUT
    
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
      rescue => e
        Rails.logger.warn "Radiator::FollowApi Falling back to: #{fallback_api_url}"
        @follow_api = nil
        follow_api(fallback_api_url)
        timeout e
      end
    end
    
    response
  end
  
  def mvests
    MvestsLookupJob.latest_mvests(site_prefix)
  end
  
  def to_rep(raw)
    raw = raw.to_i
    neg = raw < 0
    level = Math.log10(raw.abs)
    level = [level - 9, 0].max
    level = (neg ? -1 : 1) * level
    level = (level * 9) + 25
    level.to_i
  end

  def base_value(raw)
    raw.split(' ').first.to_i
  end

  def symbol_value(raw)
    raw.split(' ').last
  end
  
  def ignoring_author(author)
    @@IGNORE_CACHE ||= {}
    
    @@IGNORE_CACHE[author] ||= follow_api_execute(:get_followers, author, nil, 'ignore', 100).
      result.map(&:follower).reject(&:nil?)
  end
  
  def tags
    @tags_data ||= api_execute(:get_trending_tags, nil, 100).result
    @tags = @tags_data.map do |tag|
      if tag.respond_to? :tag
        tag.tag # golos style
      elsif tag.respond_to? :name
        tag.name # steem style
      else
        tag # unknown style
      end
    end
  end
end
