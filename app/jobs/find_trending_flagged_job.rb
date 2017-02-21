class FindTrendingFlaggedJob < ApplicationJob
  include ApplicationHelper
  
  @@DISCUSSIONS = {}

  queue_as :default

  def perform(*args)
    query(*args)
  end
  
  def query(options = {})
    options[:limit] ||= 100
    tag = options[:tag]
    flagged_by = options.delete(:flagged_by) || []
    by_trending = discussions_by_trending(options)

    @@DISCUSSIONS[tag] = by_trending.map do |comment|
      next unless (flaggers = comment.active_votes.map do |vote|
        if flagged_by.any?
          vote.voter if vote.percent < 0 && flagged_by.include?(vote.voter)
        else
          vote.voter if vote.percent < 0
        end
      end.compact).any?
      
      build_discussion_hash(comment, flaggers)
    end.compact
  end
  
  def build_discussion_hash(comment, flaggers)
    {
      symbol: symbol_value(comment.total_pending_payout_value),
      url: comment.url,
      from: flaggers,
      slug: comment.url.split('@').last,
      timestamp: comment.cashout_time,
      votes: comment.active_votes.size,
      title: comment.title,
      content: comment.body,
      author: comment.author,
      author_reputation: to_rep(comment.author_reputation)
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
