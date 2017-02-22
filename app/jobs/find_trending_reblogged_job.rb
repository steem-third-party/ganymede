class FindTrendingRebloggedJob < ApplicationJob
  include ApplicationHelper
  
  @@DISCUSSIONS = {}

  queue_as :default

  def perform(*args)
    query(*args)
  end
  
  def query(options = {})
    options[:limit] ||= 100
    tag = options[:tag]
    by_trending = discussions_by_trending(options)

    @@DISCUSSIONS[tag] = by_trending.map do |comment|
      # next unless comment.reblogged_by.any? # Doesn't work in HF 16
      next unless (reblogging = reblogging_comment(comment.author)).any?
      
      build_discussion_hash(comment, reblogging)
    end.compact
  end
  
  def build_discussion_hash(comment)
    {
      symbol: symbol_value(comment.total_pending_payout_value),
      url: comment.url,
      # from: comment.reblogged_by, # Doesn't work in HF 16.
      from: reblogging,
      slug: comment.url.split('@').last,
      timestamp: comment.cashout_time,
      votes: comment.active_votes.size,
      title: comment.title,
      content: comment.body,
      author: comment.author,
      author_reputation: to_rep(comment.author_reputation),
      reblogging_vests: total_author_vests(reblogging)
    }
  end
  
  def discussions_by_trending(options = {})
    response = api_execute(:get_discussions_by_trending, options)
    response.result
  end
  
  def self.discussions_keys
    @@DISCUSSIONS.keys
  end
  
  def self.discussions(tag = nil)
    @@DISCUSSIONS[tag]
  end
end
