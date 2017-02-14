module DiscussionsHelper
  TRUE_STRING = 'true'.freeze

  def discussion_title
    title = 'Gamymede - '
    
    title << case TRUE_STRING
    when @other_promoted then 'Promoted by Third Parties'
    when @predicted then 'Predicted to Trend'
    when @trending_by_reputation then 'Reputation on Trending'
    when @trending_by_rshares then 'Rshares on Trending'
    when @trending_flagged then 'Flagged on Trending'
    when @trending_ignored then 'Ignored on Trending'
    when @vote_ready then 'Vote Ready'
    when @flagwar then 'Flag War'
    when @first_post then 'First Post'
    else; 'Untitled'
    end
  end
  
  def discussion_active_class(current_tab, classes = [])
    classes << case [current_tab, TRUE_STRING]
    when [:other_promoted, @other_promoted] then 'active'
    when [:predicted, @predicted] then 'active'
    when [:trending, @trending_by_reputation] then 'active'
    when [:trending, @trending_flagged] then 'active'
    when [:trending, @trending_ignored] then 'active'
    when [:trending, @trending_by_rshares] then 'active'
    when [:vote_ready, @vote_ready] then 'active'
    when [:flagwar, @flagwar] then 'active'
    when [:first_post, @first_post] then 'active'
    end
    
    classes.join(' ').strip
  end
  
  def group_pattern(discussion)
    case TRUE_STRING
    when @other_promoted
      [time_ago_in_words(discussion[:timestamp]), discussion[:from], discussion[:amount]]
    when @predicted
      [time_ago_in_words(discussion[:timestamp]), discussion[:amount]]
    when @trending_by_reputation
      [discussion[:author_reputation]]
    when @trending_by_rshares
      [discussion[:max_rshares]]
    when @trending_flagged
      [discussion[:from].size, discussion[:from]]
    when @trending_ignored
      [discussion[:from].size, discussion[:from]]
    when @vote_ready
      [time_ago_in_words(discussion[:timestamp]), discussion[:votes]]
    when @flagwar
      [time_ago_in_words(discussion[:timestamp]), discussion[:upvotes], discussion[:downvotes]]
    when @first_post
      [time_ago_in_words(discussion[:timestamp])]
    else
      [time_ago_in_words(discussion[:timestamp]), discussion[:amount]]
    end
  end
  
  def tags_for_select(selected = '')
    options_for_select tags, selected
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
