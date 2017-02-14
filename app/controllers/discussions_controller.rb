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
    @limit = params[:limit].presence || '2000'
    @tag = params[:tag].presence || nil
    @exclude_tags = params[:exclude_tags].presence || ''
    @max_votes = (params[:max_votes].presence || '10').to_i
    @min_age_in_minutes = (params[:min_age_in_minutes].presence || '30').to_i
    @min_reputation = (params[:min_reputation].presence || '25').to_i
    @max_reputation = (params[:max_reputation].presence || '99').to_i
    @min_promotion_amount = (params[:min_promotion_amount].presence || '0.001').to_f
    @min_rshares = (params[:min_rshares].presence || '25000000000000').to_i
    @max_rshares = (params[:max_rshares].presence || '99999999999999').to_i

    @discussions = []
    
    other_promoted if @other_promoted == 'true'
    predicted if @predicted == 'true'
    trending_flagged if @trending_flagged == 'true'
    trending_by_reputation if @trending_by_reputation == 'true'
    trending_ignored if @trending_ignored == 'true'
    trending_by_rshares if @trending_by_rshares == 'true'
    vote_ready if @vote_ready == 'true'
    flagwar if @flagwar == 'true'
    first_post if @first_post == 'true'
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
    
    respond_to do |format|
      format.html { render 'other_promoted', layout: action_name != 'card' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('other_promoted') }
    end
  end
  
  def predicted
    data_labels = %w(
      author_reputation percent_steem_dollars promoted category net_votes
      total_pending_payout_value
    )
    prediction_label = data_labels.last

    options = {
      limit: 100
    }

    options[:tag] = @tag if !!@tag

    response = api_execute(:get_discussions_by_trending, options)
    trending_comments = response.result

    data_items = trending_comments.map do |comment|
      data_labels.map do |label|
        case label
        when 'author_reputation'; to_rep comment[label]
        when 'promoted'; base_value comment[label]
        when 'total_pending_payout_value'; base_value comment[label]
        else; comment[label]
        end
      end
    end
    
    render 'predicted', layout: action_name != 'card' and return if data_items.empty?

    data_set = Ai4r::Data::DataSet.new data_labels: data_labels, data_items: data_items
    id3 = Ai4r::Classifiers::ID3.new.build(data_set)

    response = api_execute(:get_discussions_by_created, options)
    new_comments = response.result - trending_comments
     
    predictions = new_comments.map do |comment|
      next unless comment.mode == 'first_payout'

      data_item = data_labels.map do |label|
        case label
        when 'author_reputation'; to_rep comment[label]
        when 'promoted'; base_value comment[label]
        when 'total_pending_payout_value'; base_value comment[label]
        else; comment[label]
        end
      end

      prediction = (id3.eval(data_item) rescue nil)

      next if prediction.nil?

      {
        difference: prediction - base_value(comment.total_pending_payout_value),
        symbol: symbol_value(comment.total_pending_payout_value),
        url: comment.url,
        slug: comment.url.split('@').last,
        cashout_time: comment.cashout_time,
        votes: comment.active_votes.size,
        title: comment.title,
        content: comment.body,
        author: comment.author,
        author_reputation: to_rep(comment.author_reputation)
      }
    end.reject(&:nil?)

    if predictions.any?
      @discussions += predictions.sort_by { |p| p[:difference] }.map do |prediction|
        {
          slug: prediction[:slug],
          url: prediction[:url],
          from: prediction[:slug].split('@').last.split('/').first,
          amount: prediction[:difference],
          timestamp: prediction[:cashout_time],
          symbol: prediction[:symbol],
          votes: prediction[:votes],
          title: prediction[:title],
          content: prediction[:content],
          author: prediction[:author],
          author_reputation: prediction[:author_reputation]
        }
      end
    end
    
    respond_to do |format|
      format.html { render 'predicted', layout: action_name != 'card' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('predicted') }
    end
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
    
    respond_to do |format|
      format.html { render 'trending_by_reputation', layout: action_name != 'card' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('trending_by_reputation') }
    end
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
    
    respond_to do |format|
      format.html { render 'trending_by_rshares', layout: action_name != 'card' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('trending_by_rshares') }
    end
  end
  
  def trending_flagged
    response = api_execute(:get_discussions_by_trending, limit: 100)
    
    @discussions += response.result.map do |comment|
      next unless (flaggers = comment.active_votes.map do |vote|
        vote.voter if vote.percent < 0
      end.reject(&:nil?)).any?
      
      {
        symbol: symbol_value(comment.total_pending_payout_value),
        url: comment.url,
        from: flaggers.map { |f| "<a href=\"#{site_prefix}/@#{f}\">#{f}</a>" },
        slug: comment.url.split('@').last,
        timestamp: comment.cashout_time,
        votes: comment.active_votes.size,
        title: comment.title,
        content: comment.body,
        author: comment.author,
        author_reputation: to_rep(comment.author_reputation)
      }
    end.reject(&:nil?)
    
    respond_to do |format|
      format.html { render 'trending_flagged', layout: action_name != 'card' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('trending_flagged') }
    end
  end

  def trending_ignored
    response = api_execute(:get_discussions_by_trending, limit: 25)
    
    @discussions += response.result.map do |comment|
      next unless (ignoring = ignoring_author(comment.author)).any?
      
      {
        symbol: symbol_value(comment.total_pending_payout_value),
        url: comment.url,
        from: ignoring.map { |f| "<a href=\"#{site_prefix}/@#{f}\">#{f}</a>" },
        slug: comment.url.split('@').last,
        timestamp: comment.cashout_time,
        votes: comment.active_votes.size,
        title: comment.title,
        content: comment.body,
        author: comment.author,
        author_reputation: to_rep(comment.author_reputation)
      }
    end.reject(&:nil?)
    
    respond_to do |format|
      format.html { render 'trending_ignored', layout: action_name != 'card' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('trending_ignored') }
    end
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
    
    respond_to do |format|
      format.html { render 'vote_ready', layout: action_name != 'card' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('vote_ready') }
    end
  end
  
  def flagwar
    FindFlagwarJob.perform_later(tag: @tag)
    
    # this will give us the discussions from lastest request
    @discussions = FindFlagwarJob.discussions(@tag) || []
    
    respond_to do |format|
      format.html { render 'flagwar', layout: action_name != 'card' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('flagwar') }
    end
  end
  
  def first_post
    FindFirstPostJob.perform_later(tag: @tag, min_reputation: @min_reputation, exclude_tags: @exclude_tags)
    
    # this will give us the discussions from lastest request
    @discussions = FindFirstPostJob.discussions(@tag) || []
    
    respond_to do |format|
      format.html { render 'first_post', layout: action_name != 'card' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('first_post') }
    end
  end
  
  def send_urls(filename)
    urls = @discussions.map do |discussion|
      "#{site_prefix}#{discussion[:url]}"
    end
    
    send_data urls.join("\n"), filename: "#{filename}.txt", content_type: 'text/plain', disposition: :attachment
  end
end
