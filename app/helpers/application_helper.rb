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
    if Rails.env.test?
      'https://steemd.steemit.com'
    elsif Rails.env.development?
      'https://steemd.steemit.com'
    else
      ENV['API_URL'] || 'https://node.steem.ws:443'
    end
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
    _api_execute(:api, m, *options)
  end
  
  def follow_api_execute (m, *options)
    _api_execute(:follow_api, m, *options)
  end
  
  def _api_execute (a, m, *options)
    response = nil
    
    loop do
      begin
        response = send(a).send(m, *options)
        break if !!response
      rescue => e
        Rails.logger.warn "Falling back to: #{fallback_api_url}"
        instance_variable_set "@#{a}", nil
        send(a, fallback_api_url)
        timeout e
      end
    end
    
    response
  end
  
  def steemit?
    site_prefix =~ /steemit/
  end
  
  def golos?
    site_prefix =~ /golos/
  end
  
  def mvests
    placeholder = if golos?
      "Looking up MGESTS ..."
    elsif steemit?
      "Looking up MVESTS ..."
    else
      "Looking up MTESTS ..."
    end

    MvestsLookupJob.latest_mvests(placeholder)
  end
  
  # Converts a raw reputation score to a reputation level, e.g.:
  # 119307203632653 -> 70
  def to_rep(raw)
    raw = raw.to_i
    neg = raw < 0
    level = Math.log10(raw.abs)
    level = [level - 9, 0].max
    level = (neg ? -1 : 1) * level
    level = (level * 9) + 25
    level.to_i
  end
  
  # Converts a reputation level to a raw reputation score, e.g.:
  # 70 -> 119307203632653
  def from_level(level)
    level = level.to_f
    neg = level < 0
    raw = (neg ? level + 25 : level - 25) / 9
    raw = [raw + 9, 0].max
    (raw = 10 ** raw).to_i
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
  
  def reblogging_comment(permlink)
    [] # ???
  end
  
  def total_author_vests(authors)
    @TOTAL_AUTHOR_VESTS_CACHE ||= {}
    
    unless !!@TOTAL_AUTHOR_VESTS_CACHE[authors]
      response = api_execute(:get_accounts, authors)
      
      @TOTAL_AUTHOR_VESTS_CACHE[authors] = response.result.map do |author|
        author.vesting_shares.split(' ').first.to_i
      end.sum
    end
    
    @TOTAL_AUTHOR_VESTS_CACHE[authors]
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
  
  def adaptive_media_single_photo(photo_url)
    content = <<-DONE
    <div class="AdaptiveMedia-singlePhoto">
    <div
      class="AdaptiveMedia-photoContainer js-adaptive-photo"
      data-image-url="#{photo_url}"
      data-element-context="platform_photo_card">
      <img data-aria-label-part src="#{photo_url}"
        alt="" style="width: 100%; top: -0px;" />
    </div>
    DONE
    
    content.html_safe
  end
  
  def version
    content_tag(:pre, class: "version", style: 'color: #FFFFFF') do
      ("Repo Revision: #{File.read('.revision').strip rescue '?'}; " +
      "Repo Timestamp: #{File.ctime('.revision') rescue '?'}").html_safe
    end
  end
end
