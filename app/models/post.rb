class Post
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in collection: 'Posts'
  
  scope :root_posts, -> { where(depth: 0) }
  scope :comments, -> { where(:depth.ne => 0) }
  scope :mode, lambda { |mode| where(mode: mode) }
  scope :first_payout, -> { mode 'first_payout' }
  scope :second_payout, -> { mode 'second_payout' }
  scope :archived, -> { mode 'archived '}
  scope :has_zero_pending_payout, -> { where('pending_payout_value.amount' => 0)}
  scope :has_non_zero_pending_payout, -> { where('pending_payout_value.amount' => {'$ne' => 0 })}
  scope :has_active_votes, -> { where(:"active_votes.0".exists => true) }
  scope :has_upvotes, lambda { |min_percent = 1| where('active_votes.percent' => {'$gte' => min_percent}) }
  scope :has_downvotes, lambda { |max_percent = -1| where('active_votes.percent' => {'$lte' => max_percent}) }
  scope :has_children, -> { where(:children.ne => 0) }
  scope :permlink, lambda { |permlink| where(permlink: permlink) }
  scope :tag, lambda { |tag| where('json_metadata.tags' => tag) }
  scope :payout_declined, -> { where('max_accepted_payout.amount' => 0)}
  scope :not_payout_declined, -> { where('max_accepted_payout.amount' => {'$ne' => 0}) }
  scope :author, lambda { |author| where(author: author) }

  scope :by_cashout, -> {
    order(cashout_time: :desc)
  }
  
  def self.find_flag_war
  end
  
  def commented_on?(name, options = {})
    replies.map do |reply|
      false if !!options[:min_reputation] && reply['author_reputation'].to_i < options[:min_reputation]
      
      reply['author'] == name
    end.uniq.include? true
  end
end
