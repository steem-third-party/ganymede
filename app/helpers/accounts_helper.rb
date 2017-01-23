module AccountsHelper
  def account_active_class(current_tab, classes = [])
    classes << case current_tab
    when :downvoted
      'active' if @downvoted == 'true'
    end
    
    classes.join(' ')
  end
end
