require 'open-uri'

class AccountsController < ApplicationController
  helper_method :suggested_voters, :votes_today, :accounts
  
  def index
    init_params
    @oldest_vote = nil
    
    upvoted if @upvoted == 'true'
    downvoted if @downvoted == 'true'
    unvoted if @unvoted == 'true'
    metadata if @metadata == 'true'
    voting if @voting == 'true'
  end
private
  def init_params
    {
      voters: nil, account_names: nil, upvoted: 'false', downvoted: 'false',
      unvoted: 'false', metadata: 'false', voting: 'false'
    }.each do |k, v|
      instance_variable_set("@#{k}", params[k].presence || v)
    end
  end
  
  def self.rshares_json(rshares_json_url)
    @@RSHARES_JSON ||= JSON[open(rshares_json_url).read]
  end

  def self.downvotes_json(downvotes_json_url)
    @@DOWNVOTES_JSON ||= JSON[open(downvotes_json_url).read]
  end
  
  def accounts
    @accounts ||= !!@voters ? voters(@type, @voters.split(' ')) : []
  end
  
  def upvoted
    @type = :up
    votes_today
    render_accounts(:upvoted)
  end
  
  def downvoted
    @type = :down
    votes_today
    render_accounts(:downvoted)
  end
  
  def unvoted
    @type = :un
    render_accounts(:unvoted)
  end
  
  def metadata
    @accounts = api_execute(:get_accounts, @account_names.split(' ')).result unless @account_names.nil?
    render_accounts(:metadata)
  end
  
  def voting
    @accounts = {}
    
    if !!@account_names
      @account_names.split(' ').each do |account|
        @accounts[account] = api_execute(:get_account_votes, account).result or next
      end
    end
    
    render_accounts(:voting)
  end
  
  def render_accounts(type)
    respond_to do |format|
      format.html { render type }
      format.text {
        send_data accounts.join("\n"), filename: "#{type}.txt", content_type: 'text/plain', disposition: :attachment
      }
    end
  end
  
  def fetch_voters
    if @upvoted == 'true'
      AccountsController.rshares_json(rshares_json_url).last["voters"]
    else
      AccountsController.downvotes_json(downvotes_json_url).last["accounts"]
    end
  end
  
  def suggested_voters
    return @suggested_voters if !!@suggested_voters
    
    @suggested_voters = fetch_voters.sort_by do |a|
      a.last["votes"].to_i
    end.reverse.map do |account|
      voter = account.last
      {voter["voter"] => voter["votes"]}
    end
  end
  
  def voters(type, voters)
    @@VOTERS_CACHE ||= {}
    Rails.logger.info "Voters cache size: #{@@VOTERS_CACHE.map { |key, value| {key => value.size} }}"
    
    @@VOTERS_CACHE[{type => voters}] ||= voters.map do |voter|
      result = api_execute(:get_account_votes, voter).result or next
      
      result.map do |vote|
        vote.authorperm.split('/').first if vote_match? type, vote
      end
    end.flatten.compact.uniq
  end
  
  def vote_match?(type, vote)
    case type
    when :up then vote.percent > 0
    when :down then vote.percent < 0
    when :un then vote.percent == 0
    else; true
    end
  end
  
  def votes_today
    (@voters || []).split(' ').map do |voter|
      suggested_voters.map do |v|
        next unless v.keys.first == voter
        "#{voter}: #{view_context.pluralize(v.values.last, 'vote')}"
      end
    end.flatten.compact
  end
end
