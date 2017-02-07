cache [expires_in: 1.hour] do
  atom_feed do |feed|
    feed.body @pair
      
    cache ['rss-ticker', full_title] do
      feed.entry({}, url: ticker_url(@pair, rev: md5_title[0..7]), id: md5_title) do |entry|
        entry.title full_title
        entry.content adaptive_media_single_photo(ticker_url(@pair, md5: md5_title, format: :png))
      end
    end
  end
end
