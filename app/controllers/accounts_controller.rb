require 'open-uri'

class AccountsController < ApplicationController
  def index
    @voters = params[:voters].presence || ''
    @downvoted = params[:downvoted].presence || 'false'
    @accounts = []
    
    downvoted if @downvoted == 'true'
  end
  
  def downvoted
    # downvotes_json = JSON[open('https://steemdb.com/api/downvotes').read]
    # @voters = downvotes_json.last["accounts"].map do |account|
    #   account.last["voter"]
    # end
    
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
