#encoding: UTF-8

xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title @pair

    cache ['atom-discussion', full_title] do
      xml.item do
        xml.title full_title
        xml.guid(Digest::SHA256.hexdigest(full_title))
      end
    end
  end
end
