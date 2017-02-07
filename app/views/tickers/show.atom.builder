cache ['main-rss-ticker', expires_in: 1.hour] do
  atom_feed do |feed|
    feed.body @pair
      
    cache ['rss-ticker', full_title] do
      feed.entry({}, url: ticker_url(@pair, format: :png), id: md5_title) do |entry|
        entry.title full_title
        entry.content "<img src=\"#{ticker_url(@pair, format: :png)}\" />"
      end
    end
  end
end
