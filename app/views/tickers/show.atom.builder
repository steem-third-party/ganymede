atom_feed do |feed|
  feed.body @pair
    
  cache ['atom-discussion', full_title] do
    feed.entry({}, url: ticker_url(@pair, format: :png), id: md5_title) do |entry|
      entry.title full_title
      entry.content "<img src=\"#{tickers_url(@pair, format: :png)}\" />"
    end
  end
end
