class MvestsLookupJob < ApplicationJob
  include ApplicationHelper
  queue_as :default
  
  @@LATEST_MVESTS = nil

  def perform(*_args)
    feed_history = api_execute(:get_feed_history).result
    steem_per_mvest = api_execute(:steem_per_mvest)

    current_median_history = feed_history.current_median_history
    base = current_median_history.base
    base = base.split(' ').first.to_f
    quote = current_median_history.quote
    quote = quote.split(' ').first.to_f

    steem_per_usd = (base / quote) * steem_per_mvest

    # E.g. from 2016/11/25: 1 MV = 1M VESTS = 459.680 STEEM = $50.147
    @@LATEST_MVESTS = if site_prefix =~ /golos/
      "1 MG = 1M GESTS = #{("%.3f" % steem_per_mvest)} GOLOS = #{("%.3f" % steem_per_usd)} GBG"
    else
      "1 MV = 1M VESTS = #{("%.3f" % steem_per_mvest)} STEEM = $#{("%.3f" % steem_per_usd)}"
    end
  end
  
  def self.latest_mvests(site_prefix)
    return @@LATEST_MVESTS if !!@@LATEST_MVESTS
    
    if site_prefix =~ /golos/
     "Looking up MGESTS ..."
   else
     "Looking up MVESTS ..."
   end
  end
end
