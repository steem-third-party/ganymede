class FindFlagwarMongoidJob < ApplicationJob
  include ApplicationHelper
  
  @@DISCUSSIONS_CACHE = {}

  queue_as :default

  def perform(*args)
    query(*args)
  end
  
  def query(options = {})
    @downvoter_names = []
    @downvoter_accounts = nil
    by_cashout = Post.root_posts.first_payout.has_non_zero_pending_payout.
      has_downvotes(500).has_children.not_payout_declined.by_cashout

    if !!options[:tag]
      by_cashout = by_cashout.permlink(options[:tag])
    end
    
    # prefetch all of the downvoter accounts.
    by_cashout.each do |post|
      downvotes = post.active_votes.each do |vote|
        if vote['percent'] < -500
          @downvoter_names << vote['voter']
        end
      end
    end
    
    @@DISCUSSIONS_CACHE[options[:tag]] = by_cashout.map do |post|
      votes = post.active_votes
      upvotes = votes.map do |vote|
        vote if vote['percent'] > 0
      end.reject(&:nil?)
      downvotes = votes.map do |vote|
        vote if vote['percent'] < -500
      end.reject(&:nil?)
      unvotes = votes.map do |vote|
        vote if vote['percent'] == 0
      end.reject(&:nil?)
      
      next if upvotes.none? # no upvotes, don't care
      next if downvotes.none? # no downvotes, don't care

      # Looking up downvotes that qualify.
      qualified_downvotes = votes.map do |vote|
        vote if vote['percent'] < -500 && post.commented_on?(author: vote['voter'], min_reputation: 0)
      end.reject(&:nil?)
      
      next if qualified_downvotes.none? # no qualified downvotes, don't care

      {
        symbol: post.total_pending_payout_value['asset'],
        amount: post.total_pending_payout_value['amount'],
        url: post.url,
        from: post.author,
        slug: post.url.split('@').last,
        timestamp: post.created,
        votes: post.active_votes.size,
        upvotes: upvotes.size,
        downvotes: downvotes.size,
        unvotes: unvotes.size,
        title: post.title,
        content: post.body,
        author_reputation: to_rep(post.author_reputation)
      }
    end.reject(&:nil?)
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
