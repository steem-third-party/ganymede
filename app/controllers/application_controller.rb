class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  helper_method :api, :follow_api

private
  def api
    @@API ||= Radiator::Api.new(url: 'https://node.steem.ws:443')
  end
  
  def follow_api
    @@FOLLOW_API ||= Radiator::FollowApi.new(url: 'https://node.steem.ws:443')
  end
end
