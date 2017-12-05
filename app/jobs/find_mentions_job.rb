class FindMentionsJob < ApplicationJob
  include ApplicationHelper
  
  queue_as :default

  def perform(*args)
    query(*args)
  end
  
  def query(options = {})
    tag = options[:tag]
    min_reputation = options[:min_reputation].presence || 25
    only_posts = options[:only_posts].presence || true
    exclude_tags = options[:exclude_tags].presence || ''
    account_names = options[:account_names].presence || ''
    after = options[:after] || 2.days.ago.to_date

    account_names = account_names.split(' ')
    match = comments.where("created >= ?", after.beginning_of_day)
    match = match.where("author_reputation > ?", from_level(min_reputation))
    match = match.where("depth < 1") if only_posts
    match = match.where.not(author: account_names.map { |n| n.split('-').last })
    
    account_names.each do |name|
      if name =~ /^-/
        match = match.where("body NOT LIKE ?", "%@#{name.split('-').last}%")
      else
        match = match.where("body LIKE ?", "%@#{name}%")
      end
    end
    
    match.order(:created)
  end
private
  def comments
    if steemit?
      SteemApi::Comment
    elsif golos?
      GolosCloud::Comment
    end
  end
end
