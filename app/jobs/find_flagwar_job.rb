class FindFlagwarJob < ApplicationJob
  include ApplicationHelper
  
  @@DISCUSSIONS = {}

  queue_as :default

  def perform(*args)
    query(*args)
  end
  
  def query(options = {})
    options[:limit] ||= 100
    tag = options[:tag]
    by_cashout = discussions_by_cashout(tag, options)

    prefetch_downvoters(by_cashout)
    
    @@DISCUSSIONS[tag] = by_cashout.map do |comment|
      next if skip_discussion? comment
      
      upvotes, downvotes, unvotes = extract_votes comment
      
      next if upvotes.none? # no upvotes, don't care
      next if downvotes.none? # no downvotes, don't care

      # Looking up downvotes that qualify.
      qualified_downvotes = downvotes.map do |vote|
        vote if commented_on?(author: vote.voter, parent_author: comment.author, parent_permlink: comment.permlink)
      end.compact
      
      next if qualified_downvotes.none? # no qualified downvotes, don't care

      build_discussion_hash(comment, upvotes, downvotes, unvotes)
    end.compact
  end
  
  def extract_votes(comment)
    votes = comment.active_votes
    
    [
      votes.map { |vote| vote if vote.percent > 0 }.compact,
      votes.map { |vote| vote if vote.percent < -500 }.compact,
      votes.map { |vote| vote if vote.percent == 0 }.compact
    ]
  end
  
  def build_discussion_hash(comment, upvotes, downvotes, unvotes)
    {
      symbol: symbol_value(comment.total_pending_payout_value),
      amount: base_value(comment.total_pending_payout_value),
      url: comment.url,
      from: comment.author,
      slug: comment.url.split('@').last,
      timestamp: Time.parse(comment.created + 'Z'),
      votes: comment.active_votes.size,
      upvotes: upvotes.size,
      downvotes: downvotes.size,
      unvotes: unvotes.size,
      title: comment.title,
      content: comment.body,
      author_reputation: to_rep(comment.author_reputation)
    }
  end
  
  def skip_discussion?(comment)
    [
      comment.children < 1, # nobody bothered to comment, don't care
      base_value(comment.max_accepted_payout) == 0, # payout declined, don't care
      base_value(comment.pending_payout_value) < 0.001, # no author payout, don't care
      base_value(comment.total_pending_payout_value) < 0.001, # no payout, don't care
    ].include? true
  end
  
  def prefetch_downvoters(discussions)
    @downvoter_names ||= []
    
    discussions.each do |comment|
      comment.active_votes.each do |vote|
        if vote.percent < -500
          @downvoter_names << vote.voter
        end
      end
    end
  end
  
  def discussions_by_cashout(tag, options = {})
    by_cashout = []
    
    if !!tag
      response = api_execute(:get_discussions_by_cashout, options)
      by_cashout += response.result
    else
      tags.each do |t|
        break if by_cashout.uniq.size > 250
        
        begin
          options[:tag] = t
          response = api_execute(:get_discussions_by_cashout, options)
          result_size = response.result.size
          by_cashout += response.result
          Rails.logger.info("Got discussions for tag \"#{t}\": #{result_size}, (unique total: #{by_cashout.uniq.size})")
        rescue => e
          Rails.logger.warn("Skipping: #{t} (#{e.inspect})")
        end
      end
    end
    
    by_cashout.map do |comment|
      comment if !!comment.active_votes
    end.compact.uniq
  end
  
  def commented_on?(options = {})
    return false unless commented_any? options[:author]
    
    response = api_execute(:get_content_replies, options[:parent_author], options[:parent_permlink])
    commented = response.result.map(&:author).include? options[:author]
    
    Rails.logger.info("#{options[:author]} flagged and wrote a comment for #{options[:parent_author]}'s post: #{commented}")
    
    commented
  end
  
  def commented_any?(author)
    downvoter_accounts.map do |account|
      # Author has made at least one post (thus exposed to flag).
      if account.name == author && account.post_count > 0
        # Author reputation is above 25 (0 is Rep 25), meaning their comments
        # are not being consistently flagged.
        if account.reputation.to_i > 0
          author
        end
      end
    end.compact.include? author
  end
  
  def downvoter_accounts
    @downvoter_accounts ||= if @downvoter_names.any?
      Rails.logger.info "Doing a query of downvoters: #{@downvoter_names.size}"
    
      response = api_execute(:get_accounts, @downvoter_names.uniq)
      response.result
    end
  end
  
  def self.discussions_keys
    @@DISCUSSIONS.keys
  end
  
  def self.discussions(tag = nil)
    @@DISCUSSIONS[tag]
  end
end
