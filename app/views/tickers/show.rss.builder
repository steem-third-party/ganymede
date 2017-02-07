#encoding: UTF-8

cache ['main-atom-ticker', expires_in: 1.hour] do
  xml.instruct! :xml, :version => "1.0"
  xml.rss :version => "2.0" do
    xml.channel do
      xml.title @pair

      cache ['atom-ticker', full_title] do
        xml.item do
          xml.title full_title
          xml.guid md5_title
          xml.link ticker_url(@pair, md5: md5_title)
          xml.description adaptive_media_single_photo(ticker_url(@pair, md5: md5_title, format: :png))
        end
      end
    end
  end
end
