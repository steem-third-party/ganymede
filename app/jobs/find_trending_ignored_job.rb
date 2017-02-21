class FindTrendingIgnoredJob < ApplicationJob
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
      next unless (ignoring = ignoring_author(comment.author)).any?
      
      build_discussion_hash(comment, ignoring)
    end.compact
  end
  
  def build_discussion_hash(comment, ignoring)
    {
      symbol: symbol_value(comment.total_pending_payout_value),
      url: comment.url,
      from: ignoring,
      slug: comment.url.split('@').last,
      timestamp: comment.cashout_time,
      votes: comment.active_votes.size,
      title: comment.title,
      content: comment.body,
      author: comment.author,
      author_reputation: to_rep(comment.author_reputation),
      ignoring_vests: total_author_vests(ignoring)
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
