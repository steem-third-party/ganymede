atom_feed do |feed|
  feed.body @pair
    
  cache ['atom-discussion', full_title] do
    feed.entry({}, url: ticker_url(@pair), id: Digest::SHA256.hexdigest(full_title)) do |entry|
      entry.title full_title
    end
  end
end
