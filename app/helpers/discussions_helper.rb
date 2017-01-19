module DiscussionsHelper
  def group_pattern(discussion)
    if @other_promoted == 'true'
      [time_ago_in_words(discussion[:timestamp]), discussion[:from], discussion[:amount]]
    else
      [time_ago_in_words(discussion[:timestamp]), discussion[:amount]]
    end
  end
  
  def tags_for_select(selected = '')
    @tags ||= api_execute(:get_trending_tags, nil, 100).result.map(&:name)
    
    options_for_select @tags, @tag
  end
end
