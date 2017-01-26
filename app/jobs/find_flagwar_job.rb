class FindFlagwarJob < ApplicationJob
  include ApplicationHelper
  
  @@DISCUSSIONS_CACHE = {}

  queue_as :default

  def perform(*args)
    query(*args)
  end
  
  def query(options = {})
    @downvoter_names = []
    @downvoter_accounts = nil

    options[:limit] ||= 100
    tag = options[:tag]
    by_cashout = []

    if !!tag
      response = api_execute(:get_discussions_by_cashout, options)
      by_cashout += response.result
    else
      tags.each do |tag|
        break if by_cashout.uniq.size > 250
        
        begin
          options[:tag] = tag
          response = api_execute(:get_discussions_by_cashout, options)
          result_size = response.result.size
          by_cashout += response.result
          Rails.logger.info("Got discussions for tag \"#{tag}\": #{result_size}, (uniqe total: #{by_cashout.uniq.size})")
        rescue => e
          Rails.logger.warn("Skipping: #{tag} (#{e.inspect})")
        end
      end
    end
    
    by_cashout = by_cashout.uniq
    
    # prefetch all of the downvoter accounts.
    by_cashout.each do |comment|
      downvotes = comment.active_votes.each do |vote|
        if vote.percent < 0
          @downvoter_names << vote.voter
        end
      end
    end
    
    @@DISCUSSIONS_CACHE[tag] = by_cashout.map do |comment|
      next unless comment.children > 0 # nobody bothered to comment, don't care
      next if base_value(comment.max_accepted_payout) == 0 # payout declined, don't care
      next if (pending_payout_value = base_value(comment.pending_payout_value)) < 0.001 # no author payout, don't care
      next if (base_total_pending_payout_value = base_value(comment.total_pending_payout_value)) < 0.001 # no payout, don't care
      
      votes = comment.active_votes
      upvotes = votes.map do |vote|
        vote if vote.percent > 0
      end.reject(&:nil?)
      downvotes = votes.map do |vote|
        vote if vote.percent < 0
      end.reject(&:nil?)
      unvotes = votes.map do |vote|
        vote if vote.percent == 0
      end.reject(&:nil?)
      
      next if upvotes.none? # no upvotes, don't care
      next if downvotes.none? # no downvotes, don't care

      # Looking up downvotes that qualify.
      qualified_downvotes = votes.map do |vote|
        vote if vote.percent < 0 && commented_on?(author: vote.voter, parent_author: comment.author, parent_permlink: comment.permlink)
      end.reject(&:nil?)
      
      next if qualified_downvotes.none? # no qualified downvotes, don't care

      {
        symbol: symbol_value(comment.total_pending_payout_value),
        amount: base_total_pending_payout_value,
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
    end.reject(&:nil?)
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
      author if account.name == author && account.post_count > 0
    end.reject(&:nil?).include? author
  end
  
  def downvoter_accounts
    if @downvoter_names.any? && @downvoter_accounts.nil?
      Rails.logger.info "Doing a query of downvoters: #{@downvoter_names.size}"
      response = api_execute(:get_accounts, @downvoter_names.uniq)
      @downvoter_accounts = response.result
    end
    
    @downvoter_accounts
  end
  
  def self.discussions(tag = nil)
    @@DISCUSSIONS_CACHE[tag]
  end
end
