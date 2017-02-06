class TickersController < ApplicationController
  def index
    @tickers = poloniex_ticker
    
    respond_to do |format|
      format.html { }
      format.json { render json: @tickers }
      format.atom { render layout: false }
      format.rss { render layout: false }
    end
  end
  
  def show
    @pair = params[:pair]
    @ticker = poloniex_order_pair(@pair)
    @details = poloniex_ticker.map do |ticker|
      ticker.last if @pair == ticker.first
    end.compact.last
    
    respond_to do |format|
      format.html { }
      format.json { render json: @ticker }
      format.atom { render layout: false }
      format.rss { render layout: false }
    end
  end
private
  def poloniex_ticker
    @poloniex_ticker ||= JSON[open('https://poloniex.com/public?command=returnTicker').read]
  end
  
  def poloniex_order_pair(pair, depth = 10)
    JSON[open("https://poloniex.com/public?command=returnOrderBook&currencyPair=#{pair}&depth=#{depth}").read]
  end
end
