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
    elsif @flagwar == 'true'
      'Flag War'
    else
      'Untitled'
    end
  end
  
  def discussion_active_class(current_tab, classes = [])
    classes << case current_tab
    when :other_promoted
      'active' if @other_promoted == 'true'
    when :predicted
      'active' if @predicted == 'true'
    when :trending
      'active' if @trending_flagged == 'true' || @trending_ignored == 'true'
    when :vote_ready
      'active' if @vote_ready == 'true'
    when :flagwar
      'active' if @flagwar == 'true'
    end
    
    classes.join(' ')
  end
  
  def group_pattern(discussion)
    if @other_promoted == 'true'
      [time_ago_in_words(discussion[:timestamp]), discussion[:from], discussion[:amount]]
    elsif @predicted == 'true'
      [time_ago_in_words(discussion[:timestamp]), discussion[:amount]]
    elsif @trending_flagged == 'true' || @trending_ignored == 'true'
      [discussion[:from].size, discussion[:from]]
    elsif @vote_ready == 'true'
      [time_ago_in_words(discussion[:timestamp]), discussion[:votes]]
    elsif @flagwar == 'true'
      [time_ago_in_words(discussion[:timestamp]), discussion[:upvotes], discussion[:downvotes]]
    else
      [time_ago_in_words(discussion[:timestamp]), discussion[:amount]]
    end
  end
  
  def tags_for_select(selected = '')
    @tags_data ||= api_execute(:get_trending_tags, nil, 100).result
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
  
  def discussion_amounts_total
    totals = {}
    
    @discussions.each do |d|
      a, s = d[:amount].split(' ')
      totals[s] ||= 0
      totals[s] += a.to_f
    end
    
    return 0 if totals.none?
    
    totals.map do |total|
      "%.3f #{total.first}" % total.last
    end.join(", ")
  end
end
