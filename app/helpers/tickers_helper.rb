module TickersHelper
  def full_title
    return @pair if @details.nil?
    
    "#{@pair} - last: #{@details['last']}, " +
    "lowest ask: #{@details['lowestAsk']}, " +
    "highest bid: #{@details['highestBid']}, " +
    "percent change: #{@details['percentChange']}, " +
    "base volume: #{@details['baseVolume']}, " +
    "quote volume: #{@details['quoteVolume']}, " +
    "high 24hr: #{@details['high24hr']},  " +
    "low 24hr: #{@details['low24hr']}"
  end
  
  def md5_title
    Digest::SHA256.hexdigest(full_title)
  end
end
