class FollowsController < ApplicationController
  def index
    @request_at = Time.now
    @activity_after = Time.parse(params[:activity_after].presence || '1970-01-01T00:00:00Z')
    @activity_before = Time.parse(params[:activity_before].presence || @request_at.to_s)
    @op = params[:op].presence || nil
    @account = params[:account].presence || nil
    @follows = []
    @accounts = {}
    @total_author_vests = 0
    
    count = -1

    if !!@op
      if !!@account
        _op, _type, _mapping = case @op
        when 'followings' then
          [:get_following, 'blog', :following]
        when 'followers' then
          [:get_followers, 'blog', :follower]
        when 'ignores' then
          [:get_following, 'ignore', :following]
        when 'ignoring' then
          [:get_followers, 'ignore', :follower]
        else
          raise "Unknown operation: #{@op}"
        end
        
        until count == @follows.size
          count = @follows.size
          response = follow_api_execute(_op, @account, @follows.last, _type, 100)
          @follows += response.result.map(&_mapping)
          @follows = @follows.uniq
          sleep 1
        end
        
        response = api_execute(:get_accounts, @follows)
        response.result.each do |account|
          @accounts[account.name] = account
          @total_author_vests += account.vesting_shares.split(' ').first.to_i
          if latest_activity(account) < @activity_after
            @follows -= [account.name]
          end
          if earliest_activity(account) > @activity_before
            @follows -= [account.name]
          end
        end
      else
        redirect_to follows_url, notice: "Please provide a user to check #{@op}."
      end
    end
  end
private
  def latest_activity(account)
    [
      Time.parse(account.last_post + 'Z'),
      Time.parse(account.last_vote_time + 'Z')
    ].min
  end
  
  def earliest_activity(account)
    [
      Time.parse(account.last_post + 'Z'),
      Time.parse(account.last_vote_time + 'Z')
    ].max
  end
end
