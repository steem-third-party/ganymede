class FindMentionsJob < ApplicationJob
  include ApplicationHelper
  
  queue_as :default

  def perform(*args)
    query(*args)
  end
  
  def query(options = {})
    tag = options[:tag]
    min_reputation = options[:min_reputation].presence || 25
    exclude_tags = options[:exclude_tags].presence || ''
    account_names = options[:account_names].presence || ''
    after = options[:after] || 2.hours.ago

    account_names = account_names.split(' ')
    match = SteemData::AccountOperation.where(type: 'comment', :timestamp.gte => after)
    
    account_names.each do |name|
      match = match.any_of(title: { '$regex' => /.*\@#{name}.*/i })
      match = match.any_of(body: { '$regex' => /.*\@#{name}.*/i })
      match = match.any_of(json_metadata: { '$regex' => /.*#{name}.*/i })
    end
    
    match
  end
end
