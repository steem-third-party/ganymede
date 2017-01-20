atom_feed do |feed|
  feed.body discussion_title
  feed.updated @discussions.map { |d| d[:timestamp] }.max
    
  @discussions.each do |d|
    cache ['atom-discussion', d] do
      feed.entry(d, url: "#{site_prefix}#{d[:url]}", published: d[:timestamp], updated: d[:timestamp], id: d[:slug]) do |entry|
        entry.title d[:title]
        entry.content markdown(d[:content])
        entry.author do |author|
          author.name "@#{d[:from]}"
        end
      end
    end
  end
end
