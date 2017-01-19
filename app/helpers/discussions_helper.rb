module DiscussionsHelper
  def group_pattern(discussion)
    if @other_promoted == 'true'
      [time_ago_in_words(discussion[:timestamp]), discussion[:from], discussion[:amount]]
    else
      [time_ago_in_words(discussion[:timestamp]), discussion[:amount]]
    end
  end
  
  def tags_for_select(selected = '')
    @tags_data = api_execute(:get_trending_tags, nil, 100).result
    @tags = @tags_data.map do |tag|
      if tag.respond_to? :tag
        tag.tag # golos style
      elsif tag.respond_to? :name
        tag.name # steem style
      else
        tag # unknown style
      end
    end
    
    options_for_select @tags, @tag
  end
end
