class DiscussionsController < ApplicationController
  def index
    @other_promoted = params[:other_promoted].presence || 'false'
    @predicted = params[:predicted].presence || 'false'
    @trending_flagged = params[:trending_flagged].presence || 'false'
    @trending_by_reputation = params[:trending_by_reputation].presence || 'false'
    @trending_ignored = params[:trending_ignored].presence || 'false'
    @trending_by_rshares = params[:trending_by_rshares].presence || 'false'
    @vote_ready = params[:vote_ready].presence || 'false'
    @flagwar = params[:flagwar].presence || 'false'
    @first_post = params[:first_post].presence || 'false'
    @mentions = params[:mentions].presence || 'false'
    @limit = params[:limit].presence || '100'
    @tag = params[:tag].presence || nil
    @exclude_tags = params[:exclude_tags].presence || ''
    @max_votes = (params[:max_votes].presence || '10').to_i
    @min_age_in_minutes = (params[:min_age_in_minutes].presence || '30').to_i
    @min_reputation = (params[:min_reputation].presence || '25').to_i
    @max_reputation = (params[:max_reputation].presence || '99').to_i
    @min_promotion_amount = (params[:min_promotion_amount].presence || '0.001').to_f
    @min_rshares = (params[:min_rshares].presence || '25000000000000').to_i
    @max_rshares = (params[:max_rshares].presence || '99999999999999').to_i
    @flagged_by = params[:flagged_by].presence || ''
    @order_by = params[:order_by].presence || ''

    @discussions = comments.none
    
    other_promoted if @other_promoted == 'true'
    predicted if @predicted == 'true'
    trending_flagged if @trending_flagged == 'true'
    trending_by_reputation if @trending_by_reputation == 'true'
    trending_ignored if @trending_ignored == 'true'
    trending_by_rshares if @trending_by_rshares == 'true'
    vote_ready if @vote_ready == 'true'
    flagwar if @flagwar == 'true'
    first_post if @first_post == 'true'
    mentions if @mentions == 'true'
  end
  
  def card
    index
  end
private
  def other_promoted
    @limit = @limit.to_i

    response = api_execute(:get_account_history, 'null', -@limit, @limit)
    history = response.result

    @discussions += history.map do |entry|
      next unless entry.last.op.first == 'transfer'
      
      timestamp = Time.parse(entry.last.timestamp + 'Z')
      op = entry.last.op.last
      from = op.from
      memo = op.memo
      amount = op.amount
      base_amount = amount.split(' ').first.to_f
      
      next if base_amount < @min_promotion_amount
      next if memo.nil? || memo.empty?
      next if memo.include? from

      slug = memo.split('@').last
      author, url = slug.split('/')
      
      {
        slug: slug,
        url: "/tag/@#{slug}",
        from: from,
        amount: amount,
        timestamp: timestamp,
        votes: nil,
        title: memo,
        content: '',
        author: author
      }
    end.reject(&:nil?)
    
    accounts = @discussions.map do |discussion|
      [discussion[:author], discussion[:from]]
    end.flatten.uniq
    
    if accounts.any?
      accounts = api_execute(:get_accounts, accounts).result
      
      @discussions.each do |discussion|
        accounts.each do |account|
          if discussion[:author] == account.name
            discussion[:author_reputation] = to_rep(account.reputation)
          end
          
          if discussion[:from] == account.name
            discussion[:from_reputation] = to_rep(account.reputation)
          end
        end
      end
    end
    
    render_discussions(:other_promoted)
  end
  
  def predicted
    @discussions = discussions(with: FindPredictedJob, tag: @tag)
    
    render_discussions(:predicted)
  end
  
  def trending_by_reputation
    response = api_execute(:get_discussions_by_trending, limit: 100)
    
    @discussions += response.result.map do |comment|
      next if (author_reputation = to_rep(comment.author_reputation)) > @max_reputation
      next if author_reputation < @min_reputation
      
      {
        symbol: symbol_value(comment.total_pending_payout_value),
        url: comment.url,
        slug: comment.url.split('@').last,
        timestamp: comment.cashout_time,
        votes: comment.active_votes.size,
        title: comment.title,
        content: comment.body,
        author: comment.author,
        author_reputation: author_reputation
      }
    end.reject(&:nil?)
    
    render_discussions(:trending_by_reputation)
  end
  
  def trending_by_rshares
    response = api_execute(:get_discussions_by_trending, limit: 100)
    
    @discussions += response.result.map do |comment|
      next if (max_rshares = comment.active_votes.map(&:rshares).map(&:to_i).max) > @max_rshares
      next if max_rshares < @min_rshares
      
      {
        symbol: symbol_value(comment.total_pending_payout_value),
        url: comment.url,
        slug: comment.url.split('@').last,
        timestamp: comment.cashout_time,
        votes: comment.active_votes.size,
        title: comment.title,
        content: comment.body,
        author: comment.author,
        max_rshares: max_rshares
      }
    end.reject(&:nil?)
    
    render_discussions(:trending_by_rshares)
  end
  
  def trending_flagged
    options = {
      with: FindTrendingFlaggedJob, tag: @tag, flagged_by: @flagged_by.split(' ')
    }
    
    @discussions = discussions(options)
    
    respond_to do |format|
      format.html { render 'trending_flagged', layout: action_name != 'card' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('trending_flagged') }
    end
  end

  def trending_ignored
    @discussions = discussions(with: FindTrendingIgnoredJob, tag: @tag)
    
    render_discussions(:trending_ignored)
  end

  def vote_ready
    options = {
      limit: 100
    }

    options[:tag] = @tag if !!@tag
    
    response = api_execute(:get_discussions_by_created, options)
    
    @discussions += response.result.map do |comment|
      next if (author_reputation = to_rep comment.author_reputation) < @min_reputation
      next unless comment.active_votes.size <= @max_votes
      next if (created = Time.parse(comment.created + 'Z')) > @min_age_in_minutes.minutes.ago
      
      comment_tags = JSON[comment.json_metadata]["tags"] rescue []
      exclude_tags = [@exclude_tags.split(' ')].flatten
      next if (comment_tags & exclude_tags).any?
      
      {
        symbol: symbol_value(comment.total_pending_payout_value),
        url: comment.url,
        from: comment.author,
        slug: comment.url.split('@').last,
        timestamp: created,
        votes: comment.active_votes.size,
        title: comment.title,
        content: comment.body,
        author_reputation: author_reputation
      }
    end.reject(&:nil?)
    
    render_discussions(:vote_ready)
  end
  
  def flagwar
    @discussions = discussions(with: FindFlagwarJob, tag: @tag)
    
    render_discussions(:flagwar)
  end
  
  def first_post
    options = {
      with: FindFirstPostJob, tag: @tag, min_reputation: @min_reputation,
      exclude_tags: @exclude_tags
    }
    
    @discussions = discussions(options)
    
    render_discussions(:first_post)
  end
  
  def mentions
    @account_names = params[:account_names]
    @after = (Time.parse(params[:after]) rescue 2.hours.ago).to_date
    @discussions = if !!@account_names
      options = {
        with: FindMentionsJob, account_names: @account_names, after: @after,
        tag: @tag, min_reputation: @min_reputation, exclude_tags: @exclude_tags
      }
      
      discussions(options)
    else
      comments.none
    end
    
    page = params[:page] || 1
    per = @limit.to_i
    @discussions = @discussions.paginate(page: page, per_page: per)
    
    render_discussions(:mentions)
  end
  
  def discussions(options = {})
    job = options.delete(:with)
    tag = options[:tag]
    
    if defined? job.discussions
      if !!job.discussions(tag)
        job.perform_now(options)
      else
        job.perform_later(options)
      end
    
      # this will give us the discussions from lastest request
      job.discussions(tag) || []
    else
      job.perform_now(options)
    end
  end
  
  def render_discussions(type)
    respond_to do |format|
      format.html { render type, layout: action_name != 'card' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls(type) }
    end
  end
  
  def send_urls(filename)
    urls = @discussions.map do |discussion|
      "#{site_prefix}#{discussion[:url]}"
    end
    
    send_data urls.join("\n"), filename: "#{filename}.txt", content_type: 'text/plain', disposition: :attachment
  end
  
  def comments
    if steemit?
      SteemApi::Comment
    elsif golos?
      GolosCloud::Comment
    end
  end
end
