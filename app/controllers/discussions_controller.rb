class DiscussionsController < ApplicationController
  def index
    @other_promoted = params[:other_promoted].presence || 'false'
    @predicted = params[:predicted].presence || 'false'
    @trending_flagged = params[:trending_flagged].presence || 'false'
    @trending_ignored = params[:trending_ignored].presence || 'false'
    @vote_ready = params[:vote_ready].presence || 'false'
    @limit = params[:limit].presence || '2000'
    @tag = params[:tag].presence || nil
    @min_reputation = (params[:min_reputation].presence || '25').to_i
    @min_promotion_amount = (params[:min_promotion_amount].presence || '0.001').to_f

    @discussions = []
    
    other_promoted if @other_promoted == 'true'
    predicted if @predicted == 'true'
    trending_flagged if @trending_flagged == 'true'
    trending_ignored if @trending_ignored == 'true'
    vote_ready if @vote_ready == 'true'
  end
private
  def other_promoted
    @limit = @limit.to_i

    response = api_execute(:get_account_history, 'null', -@limit, @limit)
    history = response.result

    @discussions += history.map do |entry|
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
      format.html { render 'other_promoted' }
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
    
    render 'index' and return if data_items.empty?

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
      format.html { render 'predicted' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('predicted') }
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
      format.html { render 'trending_flagged' }
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
      format.html { render 'trending_ignored' }
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
      next if comment.active_votes.size > 9
      next if (created = Time.parse(comment.created + 'Z')) > 30.minutes.ago
      
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
      format.html { render 'vote_ready' }
      format.atom { render layout: false }
      format.rss { render layout: false }
      format.text { send_urls('vote_ready') }
    end
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
  
  def send_urls(filename)
    urls = @discussions.map do |discussion|
      "#{site_prefix}#{discussion[:url]}"
    end
    
    send_data urls.join("\n"), filename: "#{filename}.txt", content_type: 'text/plain', disposition: :attachment
  end
end
