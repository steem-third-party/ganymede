class ApplicationController < ActionController::Base
  include ApplicationHelper

  protect_from_forgery with: :exception
  
  helper_method :markdown
private
  def markdown(string)
    RDiscount.new(string).to_html.html_safe
  end
end
