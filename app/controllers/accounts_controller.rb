require 'open-uri'

class AccountsController < ApplicationController
  def index
    @voters = params[:voters].presence || ''
    @upvoted = params[:upvoted].presence || 'false'
    @downvoted = params[:downvoted].presence || 'false'
    @accounts = []
    
    upvoted if @upvoted == 'true'
    downvoted if @downvoted == 'true'
  end
  
  def upvoted
    @suggested_voters = []
    # @@UPVOTES_JSON = JSON[open(upvotes_json_url).read]
    # @suggested_voters = @@DOWNVOTES_JSON.last["accounts"].map do |account|
    #   voter = account.last
    #   {voter["voter"] => voter["votes"]}
    # end.sort_by do |voter|
    #   voter["votes"]
    # end
    
    render 'upvoted' and return if @voters.empty?
    
    voters = @voters.split(' ')
    
    voters.each do |voter|
      response = api_execute(:get_account_votes, voter)
    
      next if response.result.nil?
      
      @accounts << response.result.map do |vote|
        vote.authorperm.split('/').first if vote.percent > 0
      end
    end
    
    @accounts = @accounts.flatten.reject(&:nil?).uniq
    
    respond_to do |format|
      format.html { render 'upvoted' }
      format.text {
        send_data @accounts.join("\n"), filename: 'upvoted.txt', content_type: 'text/plain', disposition: :attachment
      }
    end
  end
  
  def downvoted
    @@DOWNVOTES_JSON = JSON[open(downvotes_json_url).read]
    @suggested_voters = @@DOWNVOTES_JSON.last["accounts"].map do |account|
      voter = account.last
      {voter["voter"] => voter["votes"]}
    end.sort_by do |voter|
      voter["votes"]
    end
    
    render 'downvoted' and return if @voters.empty?
    
    voters = @voters.split(' ')
    
    voters.each do |voter|
      response = api_execute(:get_account_votes, voter)
    
      next if response.result.nil?
      
      @accounts << response.result.map do |vote|
        vote.authorperm.split('/').first if vote.percent < 0
      end
    end
    
    @accounts = @accounts.flatten.reject(&:nil?).uniq
    
    respond_to do |format|
      format.html { render 'downvoted' }
      format.text {
        send_data @accounts.join("\n"), filename: 'downvoted.txt', content_type: 'text/plain', disposition: :attachment
      }
    end
  end
end
