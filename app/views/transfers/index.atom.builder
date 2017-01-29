atom_feed do |feed|
  feed.body "#{@account} transfers"
  feed.updated @transfers.map { |d| d[:timestamp] }.max
    
  @transfers.each do |d|
    cache ['atom-transfer', d] do
      feed.entry(d, url: "#{site_prefix}/@#{@account}/transfers", published: d[:timestamp], updated: d[:timestamp], id: d[:trx_id]) do |entry|
        entry.title "#{d[:to]} received #{d[:amount]} from #{d[:from]}"
        entry.body d[:memo]
        entry.author do |author|
          author.name "@#{d[:from]}"
        end
      end
    end
  end
end
