module AccountsHelper
  TRUE_STRING = 'true'.freeze
  
  def account_active_class(current_tab, classes = [])
    classes << case [current_tab, TRUE_STRING]
    when [:upvoted, @upvoted] then 'active'
    when [:downvoted, @downvoted] then 'active'
    when [:unvoted, @unvoted] then 'active'
    when [:voting, @voting] then 'active'
    end
    
    classes.join(' ').strip
  end
  
  def activity_options_for_select(prefix, selected = '')
    options_for_select [
      ['', ''],
      [prefix + ' ' + time_ago_in_words(d = 6.months.ago.beginning_of_day) + ' ago', d.to_date.to_s],
      [prefix + ' ' + time_ago_in_words(d = 3.months.ago.beginning_of_day) + ' ago', d.to_date.to_s],
      [prefix + ' ' + time_ago_in_words(d = 1.month.ago.beginning_of_day) + ' ago', d.to_date.to_s]
    ], selected
  end
end
