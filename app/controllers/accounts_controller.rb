require 'open-uri'

class AccountsController < ApplicationController
  def index
    @voters = params[:voters].presence || ''
    @upvoted = params[:upvoted].presence || 'false'
    @downvoted = params[:downvoted].presence || 'false'
    @unvoted = params[:unvoted].presence || 'false'
    @account_names = params[:account_names].presence || 'false'
    @metadata = params[:metadata].presence || 'false'
    @accounts = []
    @oldest_vote = nil
    
    upvoted if @upvoted == 'true'
    downvoted if @downvoted == 'true'
    unvoted if @unvoted == 'true'
    metadata if @metadata == 'true'
  end
private
  def upvoted
    @suggested_voters = suggested_voters AccountsController.rshares_json(rshares_json_url).last["voters"]
    
    render 'upvoted' and return if @voters.empty?
    
    @accounts = voters :up, @voters.split(' ')
    votes_today

    respond_to do |format|
      format.html { render 'upvoted' }
      format.text {
        send_data @accounts.join("\n"), filename: 'upvoted.txt', content_type: 'text/plain', disposition: :attachment
      }
    end
  end
  
  def downvoted
    @suggested_voters = suggested_voters AccountsController.downvotes_json(downvotes_json_url).last["accounts"]
    
    render 'downvoted' and return if @voters.empty?
    
    @accounts = voters :down, @voters.split(' ')
    votes_today

    respond_to do |format|
      format.html { render 'downvoted' }
      format.text {
        send_data @accounts.join("\n"), filename: 'downvoted.txt', content_type: 'text/plain', disposition: :attachment
      }
    end
  end
  
  def unvoted
    render 'unvoted' and return if @voters.empty?
    
    @accounts = voters :un, @voters.split(' ')

    respond_to do |format|
      format.html { render 'unvoted' }
      format.text {
        send_data @accounts.join("\n"), filename: 'unvoted.txt', content_type: 'text/plain', disposition: :attachment
      }
    end
  end
  
  def metadata
    @accounts = api_execute(:get_accounts, @account_names.split(' ')).result
    
    respond_to do |format|
      format.html { render 'metadata' }
      format.text {
        send_data @accounts.join("\n"), filename: 'metadata.txt', content_type: 'text/plain', disposition: :attachment
      }
    end
  end
  
  def suggested_voters(voters)
    voters.sort_by do |a|
      a.last["votes"].to_i
    end.reverse.map do |account|
      voter = account.last
      {voter["voter"] => voter["votes"]}
    end
  end
  
  def voters(type, voters)
    votes = []
    
    voters.each do |voter|
      response = api_execute(:get_account_votes, voter)
      next unless !!response.result
      
      votes += response.result.map do |vote|
        voted = vote.authorperm.split('/').first
        
        case type
        when :up; next unless vote.percent > 0
        when :down; next unless vote.percent < 0
        when :un; next unless vote.percent == 0
        end
        
        voted
      end
    end
    
    votes.compact.uniq
  end
  
  def self.rshares_json(rshares_json_url)
    @@RSHARES_JSON ||= JSON[open(rshares_json_url).read]
  end
  
  def self.downvotes_json(downvotes_json_url)
    @@DOWNVOTES_JSON ||= JSON[open(downvotes_json_url).read]
  end
  
  def votes_today
    @votes_today = []
    
    @voters.split(' ').each do |voter|
      @votes_today << @suggested_voters.map do |v|
        next unless v.keys.first == voter
        "#{voter}: #{view_context.pluralize(v.values.last, 'vote')}"
      end
    end
    
    @votes_today = @votes_today.flatten.compact
  end
end
