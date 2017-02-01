class Operation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in collection: 'Operations'
  
  scope :type, lambda { |type, invert = false|
    where((invert ? :type.nin : :type.in) => [type].flatten)
  }
  scope :block_num, lambda { |block_num| where(block_num: block_num) }
  scope :author, lambda { |author| where(author: author) }
  
  scope :vote, -> { type 'vote' }
  scope :upvote, lambda { |min_vote = 0| vote.where(:weight.gt => min_vote) }
  scope :downvote, lambda { |max_vote = 0| vote.where(:weight.lt => max_vote) }
  scope :voter, lambda { |voter| vote.where(voter: voter) }
  
  scope :comment, -> { type 'comment' }
  scope :parent_permlink, lambda { |parent_permlink| where(parent_permlink: parent_permlink) }
  scope :parent_author, lambda { |parent_author| where(parent_author: parent_author) }
  scope :permlink, lambda { |permlink| where(permlink: permlink) }
  scope :tag, lambda { |tag| where('json_metadata.tags' => tag) }
end
