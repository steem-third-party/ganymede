class FindPredictedJob < ApplicationJob
  include ApplicationHelper
  
  @@DISCUSSIONS = {}

  queue_as :default

  def perform(*args)
    query(*args)
  end
  
  def query(options = {})
    data_labels = %w(
      author_reputation percent_steem_dollars promoted category net_votes
      total_pending_payout_value
    )
    prediction_label = data_labels.last
    options[:limit] ||= 100
    tag = options[:tag]

    by_trending = api_execute(:get_discussions_by_trending, options).result

    data_items = by_trending.map do |comment|
      data_labels.map do |label|
        case label
        when 'author_reputation'; to_rep comment[label]
        when 'promoted'; base_value comment[label]
        when 'total_pending_payout_value'; base_value comment[label]
        else; comment[label]
        end
      end
    end
    
    return if data_items.empty?

    data_set = Ai4r::Data::DataSet.new data_labels: data_labels, data_items: data_items
    id3 = Ai4r::Classifiers::ID3.new.build(data_set)

    by_created = api_execute(:get_discussions_by_created, options).result
    by_created = by_created - by_trending
     
    predictions = by_created.map do |comment|
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
    end.compact

    if predictions.any?
      @@DISCUSSIONS[tag] = predictions.sort_by do |p|
        p[:difference]
      end.map do |prediction|
        build_discussion_hash(prediction)
      end
    end
  end
  
  def build_discussion_hash(prediction)
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
  
  def self.discussions_keys
    @@DISCUSSIONS.keys
  end
  
  def self.discussions(tag = nil)
    @@DISCUSSIONS[tag]
  end
end
