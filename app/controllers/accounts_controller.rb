require 'open-uri'

class AccountsController < ApplicationController
  def index
    @voters = params[:voters].presence || ''
    @upvoted = params[:upvoted].presence || 'false'
    @downvoted = params[:downvoted].presence || 'false'
    @account_names = params[:account_names].presence || 'false'
    @metadata = params[:metadata].presence || 'false'
    @accounts = []
    @oldest_vote = nil
    
    upvoted if @upvoted == 'true'
    downvoted if @downvoted == 'true'
    metadata if @metadata == 'true'
  end
  
  def upvoted
    @suggested_voters = AccountsController.rshares_json(rshares_json_url).last["voters"].sort_by { |a| a.last["votes"].to_i }.reverse.map do |account|
      voter = account.last
      {voter["voter"] => voter["votes"]}
    end.sort_by do |voter|
      voter["votes"]
    end
    
    render 'upvoted' and return if @voters.empty?
    
    @voters.split(' ').each do |voter|
      response = api_execute(:get_account_votes, voter)
    
      next if response.result.nil?
      
      @accounts << response.result.map do |vote|
        @oldest_vote ||= Time.parse(vote.time + 'Z')
        @oldest_vote = [@oldest_vote, Time.parse(vote.time + 'Z')].min
        vote.authorperm.split('/').first if vote.percent > 0
      end
    end
    
    @accounts = @accounts.flatten.reject(&:nil?).uniq
    votes_today

    respond_to do |format|
      format.html { render 'upvoted' }
      format.text {
        send_data @accounts.join("\n"), filename: 'upvoted.txt', content_type: 'text/plain', disposition: :attachment
      }
    end
  end
  
  def downvoted
    @suggested_voters = AccountsController.downvotes_json(downvotes_json_url).last["accounts"].sort_by { |a| a.last["votes"].to_i }.reverse.map do |account|
      voter = account.last
      {voter["voter"] => voter["votes"]}
    end.sort_by do |voter|
      voter["votes"]
    end
    
    render 'downvoted' and return if @voters.empty?
    
    @voters.split(' ').each do |voter|
      response = api_execute(:get_account_votes, voter)
    
      next if response.result.nil?
      
      @accounts << response.result.map do |vote|
        @oldest_vote ||= Time.parse(vote.time + 'Z')
        @oldest_vote = [@oldest_vote, Time.parse(vote.time + 'Z')].min
        vote.authorperm.split('/').first if vote.percent < 0
      end
    end
    
    @accounts = @accounts.flatten.reject(&:nil?).uniq
    votes_today

    respond_to do |format|
      format.html { render 'downvoted' }
      format.text {
        send_data @accounts.join("\n"), filename: 'downvoted.txt', content_type: 'text/plain', disposition: :attachment
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
private
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
    
    @votes_today = @votes_today.flatten.reject(&:nil?)
  end
end
