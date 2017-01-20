module DiscussionsHelper
  def discussion_title
    title = 'Gamymede - '
    
    title << if @other_promoted == 'true'
      'Promoted by Third Parties'
    elsif @predicted == 'true'
      'Predicted to Trend'
    elsif @trending_flagged == 'true'
      'Flagged on Trending'
    elsif @trending_ignored == 'true'
      'Ignored on Trending'
    elsif @vote_ready == 'true'
      'Vote Ready'
    else
      'Untitled'
    end
  end
  
  def group_pattern(discussion)
    if @other_promoted == 'true'
      [time_ago_in_words(discussion[:timestamp]), discussion[:from], discussion[:amount]]
    elsif @predicted == 'true'
      [time_ago_in_words(discussion[:timestamp]), discussion[:amount]]
    elsif @trending_flagged == 'true' || @trending_ignored == 'true'
      [discussion[:from]]
    elsif @vote_ready == 'true'
      [time_ago_in_words(discussion[:timestamp]), discussion[:votes]]
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
