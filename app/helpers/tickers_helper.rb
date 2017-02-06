module TickersHelper
  def full_title
    "#{@pair} - last: #{@details['last']}, lowest ask: #{@details['lowestAsk']}, highest bid: #{@details['highestBid']}, percent change: #{@details['percentChange']}, base volume: #{@details['baseVolume']}, quote volume: #{@details['quoteVolume']}, high 24hr: #{@details['high24hr']}, low 24hr: #{@details['low24hr']}"
  end
end
