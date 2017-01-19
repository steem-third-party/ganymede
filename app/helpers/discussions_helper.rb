module DiscussionsHelper
  def group_pattern(discussion)
    if @other_promoted == 'true'
      [time_ago_in_words(discussion[:timestamp]), discussion[:from], discussion[:amount]]
    else
      [time_ago_in_words(discussion[:timestamp]), discussion[:amount]]
    end
  end
end
