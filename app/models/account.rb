class Account
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in collection: 'Accounts'

  def following_accounts; Account.where(:name.in => following); end
  def follower_accounts; Account.where(:name.in => followers); end
  def posts; Post.where(author: name); end
end
