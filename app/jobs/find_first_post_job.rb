class FindFirstPostJob < ApplicationJob
  include ApplicationHelper
  
  @@DISCUSSIONS = {}

  queue_as :default

  def perform(*args)
    query(*args)
  end
  
  def query(options = {})
    options[:limit] ||= 100
    tag = options[:tag]
    min_reputation = options[:min_reputation].presence || 25
    exclude_tags = options[:exclude_tags].presence || ''
    by_created = discussions_by_created(tag, options)

    authors = api_execute(:get_accounts, by_created.map(&:author).uniq).result

    @@DISCUSSIONS[tag] = by_created.map do |comment|
      next if (author_reputation = to_rep comment.author_reputation) < min_reputation
      
      next unless authors.map do |author|
        author.name == comment.author && author.post_count == 1
      end.compact.include? true
      
      comment_tags = JSON[comment.json_metadata]["tags"] rescue []
      exclude_tags = [exclude_tags.split(' ')].flatten
      next if (comment_tags & exclude_tags).any?
      
      build_discussion_hash(comment, author_reputation)
    end.compact
  end
  
  def build_discussion_hash(comment, author_reputation)
    {
      symbol: symbol_value(comment.total_pending_payout_value),
      url: comment.url,
      from: comment.author,
      slug: comment.url.split('@').last,
      timestamp: created = Time.parse(comment.created + 'Z'),
      votes: comment.active_votes.size,
      title: comment.title,
      content: comment.body,
      author_reputation: author_reputation
    }
  end
  
  def discussions_by_created(tag, options = {})
    response = api_execute(:get_discussions_by_created, options)
    response.result
  end
  
  def self.discussions_keys
    @@DISCUSSIONS.keys
  end
  
  def self.discussions(tag = nil)
    @@DISCUSSIONS[tag]
  end
end
