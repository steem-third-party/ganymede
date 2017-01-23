#encoding: UTF-8

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title discussion_title
    xml.updated @discussions.map { |d| d[:timestamp] }.max

    @discussions.each do |d|
      xml.item do
        xml.title d[:title]
        xml.author "@#{d[:from]}"
        xml.pubDate d[:timestamp].to_s(:rfc822)
        xml.link "#{site_prefix}#{d[:url]}"
        xml.guid d[:slug]
        xml.description "<p>#{markdown(d[:content])}</p>"
      end
    end
  end
end
