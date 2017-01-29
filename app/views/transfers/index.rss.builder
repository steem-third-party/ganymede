#encoding: UTF-8

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "#{@account} transfers"
    xml.updated @transfers.map { |d| d[:timestamp] }.max

    @transfers.each do |d|
      xml.item do
        xml.title "#{d[:to]} received #{d[:amount]} from #{d[:from]}"
        xml.author "@#{d[:from]}"
        xml.pubDate d[:timestamp].to_s(:rfc822)
        xml.link "#{site_prefix}/@#{@account}/transfers"
        xml.guid d[:trx_id]
        xml.description d[:memo]
      end
    end
  end
end
