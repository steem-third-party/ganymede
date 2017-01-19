class DiscussionsController < ApplicationController
  def index
    @other_promoted = params[:other_promoted].presence || 'false'
    @predicted = params[:predicted].presence || 'false'
    @limit = params[:limit].presence || '2000'
    @tag = params[:tag].presence || nil

    @discussions = []

    if @other_promoted == 'true'
      @limit = @limit.to_i

      response = api_execute(:get_account_history, 'null', -@limit, @limit)
      history = response.result

      @discussions += history.map do |entry|
        timestamp = Time.parse(entry.last.timestamp + 'Z')
        op = entry.last.op.last
        from = op.from
        memo = op.memo
        amount = op.amount
        
        next if memo.nil? || memo.empty?
        next if memo.include? from

        slug = memo.split('@').last
        author, url = slug.split('/')
        
        {
          slug: slug,
          url: "https://steemit.com/tag/@#{slug}",
          from: from,
          amount: amount,
          timestamp: timestamp,
          # content: api.get_content(author, url).result
        }
      end.reject(&:nil?)
    elsif @predicted == 'true'
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
          url: "https://steemit.com#{comment.url}",
          slug: comment.url.split('@').last,
          cashout_time: comment.cashout_time
        }
      end.reject(&:nil?)

      if predictions.any?
        @discussions += predictions.sort_by { |p| p[:difference] }.map do |prediction|
          {
            slug: prediction[:slug],
            url: prediction[:url],
            from: prediction[:slug].split('@').last.split('/').first,
            amount: prediction[:difference],
            timestamp: prediction[:cashout_time]
          }
        end
      end
    end
  end
private
  def to_rep(raw)
    raw = raw.to_i
    level = Math.log10(raw.abs)
    level = [level - 9, 0].max
    level = (level * 9) + 25
    level.to_i
  end

  def base_value(raw)
    raw.split(' ').first.to_i
  end

  def symbol_value(raw)
    raw.split(' ').last
  end
end
