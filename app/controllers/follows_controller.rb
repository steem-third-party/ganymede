class FollowsController < ApplicationController
  def index
    @op = params[:op].presence || nil
    @account = params[:account].presence || nil
    @follows = []
    
    count = -1

    if !!@op
      _op, _type, _mapping = case @op
      when 'followers' then
        [:get_followers, 'blog', :follower]
      when 'followings' then
        [:get_following, 'blog', :following]
      when 'ignores' then
        [:get_following, 'ignore', :following]
      when 'ignoring' then
        [:get_followers, 'ignore', :follower]
      end
      
      until count == @follows.size
        count = @follows.size
        response = follow_api_execute(_op, @account, @follows.last, _type, 100)
        @follows += response.result.map(&_mapping)
        @follows = @follows.uniq
        sleep 1
      end
    end
  end
end
