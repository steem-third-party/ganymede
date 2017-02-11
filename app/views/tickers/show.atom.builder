cache ["ticker-atom", full_title, expires_in: 1.hour] do
  atom_feed do |feed|
    feed.body @pair
    feed.updated Time.now
      
    cache ["ticker-atom", full_title] do
      feed.entry({}, url: ticker_url(@pair, rev: md5_title[0..7]), published: Time.now, updated: Time.now, id: md5_title) do |entry|
        entry.title full_title
        entry.content adaptive_media_single_photo(ticker_url(@pair, md5: md5_title, format: :png))
      end
    end
  end
end
