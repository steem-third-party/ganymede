atom_feed do |feed|
  feed.body discussion_title
  feed.updated @discussions.map { |d| d[:timestamp] }.max
    
  @discussions.each do |d|
    cache ['atom-discussion', d] do
      timestamp = d[:timestamp] || d[:created]
      slug = d[:slug] || "#{d[:author]}/#{d[:permlink]}"
      from = d[:from] || d[:author]
      
      feed.entry(d, url: "#{site_prefix}#{d[:url]}", published: timestamp, updated: timestamp, id: slug) do |entry|
        entry.title d[:title]
        entry.content "<p>#{markdown(d[:content] || d[:body])}</p>"
        entry.author do |author|
          author.name "@#{from}"
          author.blog "#{site_prefix}/@#{from}"
          author.reputation d[:author_reputation] if !!d[:author_reputation]
        end
      end
    end
  end
end
