class TickersController < ApplicationController
  include TickersHelper
  
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
      format.png { capture_steem_chart }
      format.jpeg { capture_steem_chart }
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
  
  def capture_steem_chart
    fmt = params[:format]
    base_href = "https://www.worldcoinindex.com"
    steem_btc = "#{base_href}/widget/renderWidget?size=large&from=STEEM&to=usd&clearstyle=true&ms5=#{md5_title}"
    btc_usd = "#{base_href}/widget/renderWidget?size=large&from=BTC&to=usd&clearstyle=true&ms5=#{md5_title}"
    sbd_btc = "#{base_href}/widget/renderWidget?size=large&from=SBD&to=usd&clearstyle=true&ms5=#{md5_title}"
  
    filename = "#{md5_title}.#{fmt}"
    fh = "#{Rails.root.join('tmp')}/#{filename}"
    
    File.open(fh, 'rb') do |f|
      send_data(f.read, stream: false, filename: filename, type: "image/#{fmt}", disposition: 'inline')
    end and return if File.exists? fh
  
    render_options, raster_options = {}, {}
  
    raster_options[:cache_dir] = Rails.root.join('tmp')
    raster_options[:quality] = 50
    raster_options[:zoom] = 2
    raster_options[:encoding] = 'UTF-8'
  
    content = "<base href=\"#{base_href}/\" />"
    content << "<table><tr>"
    content << "<td>#{open(steem_btc).read}</td>"
    content << "<td>#{open(btc_usd).read}</td>"
    content << "<td>#{open(sbd_btc).read}</td>"
    content << "</td></tr></table>"
    content = content.force_encoding("UTF-8")
    kit = IMGKit.new(content, raster_options)
    filename = "content.#{fmt}" unless filename.present?
    send_data(img = kit.to_img(fmt), filename: filename, stream: false, :type => "image/#{fmt}", :disposition => 'inline')
  
    File.open(fh, 'wb') do |f|
      f.write(img)
    end unless File.exists? fh
  end
end
