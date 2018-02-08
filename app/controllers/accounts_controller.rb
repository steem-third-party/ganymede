require 'open-uri'
require 'json'

class AccountsController < ApplicationController
  before_action :prune_account_votes_cache
  helper_method :suggested_voters, :votes_today, :accounts
  
  def index
    init_params
    @oldest_vote = nil
    
    voting if @voting == 'true'
    upvoted if @upvoted == 'true'
    downvoted if @downvoted == 'true'
    unvoted if @unvoted == 'true'
    metadata if @metadata == 'true'
    mvests if @mvests == 'true'
    crosscheck if @crosscheck == 'true'
  end
private
  def init_params
    {
      account_names: nil, upvoted: 'false', downvoted: 'false',
      unvoted: 'false', metadata: 'false', voting: 'false', mvests: 'false',
      crosscheck: 'false'
    }.each do |k, v|
      instance_variable_set("@#{k}", params[k].presence || v)
    end
  end
  
  def self.rshares_json(rshares_json_url)
    @@RSHARES_JSON ||= JSON[open(rshares_json_url).read] rescue []
  end

  def self.downvotes_json(downvotes_json_url)
    @@DOWNVOTES_JSON ||= JSON[open(downvotes_json_url).read] rescue []
  end
  
  def accounts
    @accounts ||= !!@account_names ? voters(@type, @account_names.split(' ')) : []
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
  
  def mvests
    @accounts = api_execute(:get_accounts, @account_names.split(' ')).result unless @account_names.nil?
    render_accounts(:mvests)
  end
  
  def crosscheck
    unless @account_names.nil?
      @accounts = @account_names.split(' ')
      @powerdowns = {}
      @powerups = {}
      @transfers = {}
      @vesting_from = {}
      @vesting_to = {}
      
      @accounts.each do |account|
        @powerdowns[account] = powerdowns(account)
        @powerups[account] = powerups(account)
        @transfers[account] = transfers(account)
        @vesting_from[account] = vesting_from(account)
        @vesting_to[account] = vesting_to(account)
      end
    end
    
    render_accounts(:crosscheck)
  end
  
  def voting
    @accounts = {}
    
    if !!@account_names
      @account_names.split(' ').each do |account|
        if !!(votes = account_votes(account))
          @accounts[account] = votes
        end
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
      json = AccountsController.rshares_json(rshares_json_url)
      
      if json.any?
        json.last["voters"]
      else
        []
      end
    else
      json = AccountsController.downvotes_json(downvotes_json_url)
      
      if json.any?
        json.last["accounts"]
      else
        []
      end
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
      result = account_votes(voter) or next
      
      @oldest_vote = result.first[:timestamp] if result.any?
      
      result.map do |vote|
        vote[:vote].author if vote_match? type, vote
      end
    end.flatten.compact.uniq
  end
  
  def vote_match?(type, vote)
    case type
    when :up then vote[:vote].weight > 0
    when :down then vote[:vote].weight < 0
    when :un then vote[:vote].weight == 0
    else; true
    end
  end
  
  def votes_today
    (@account_names || []).split(' ').map do |voter|
      suggested_voters.map do |v|
        next unless v.keys.first == voter
        "#{voter}: #{view_context.pluralize(v.values.last, 'vote')}"
      end
    end.flatten.compact
  end
  
  def account_votes(voter)
    @@ACCOUNT_VOTES_CACHE ||= {}
    @@ACCOUNT_VOTES_CACHE[voter] ||= api_execute(:get_account_history, voter, -1, 200).result.map do |index, history|
      op = history.op
      type = op.first
      next unless type == 'vote'
      
      {vote: op.last, timestamp: Time.parse(history.timestamp + 'Z')}
    end.compact
  end
  
  def prune_account_votes_cache
    return unless defined? @@ACCOUNT_VOTES_CACHE
    return if @@ACCOUNT_VOTES_CACHE.nil?
    
    @@ACCOUNT_VOTES_CACHE.reject! do |name, votes|
      return true if votes.empty?
      
      votes.last[:timestamp] > 15.minutes.ago
    end
  end
  
  def powerdowns(account)
    ret_val = ""
    
    if account.nil? || account == ''
      ret_val = 'Account name required.'
      return
    end
    
    table = SteemApi::Vo::FillVestingWithdraw.arel_table
    all = SteemApi::Vo::FillVestingWithdraw.where(table[:from_account].not_eq(table[:to_account]))
    powerdowns = if account =~ /%/
      all.where(table[:from_account].matches(account))
    else
      all.where(from_account: account)
    end
    
    if powerdowns.none?
      ret_val = "No match."
    else
      from = powerdowns.pluck(:from_account).uniq.join(', ')
      ret_val = "Powerdowns grouped by sum from #{from} ...\n"
      ret_val += JSON.pretty_generate(powerdowns.group(:to_account).
        order('sum_try_parse_replace_withdrawn_vests_as_float').
        sum("TRY_PARSE(REPLACE(withdrawn, ' VESTS', '') AS float)"))
    end
    
    ret_val
  end
  
  def powerups(account)
    ret_val = ""
    if account.nil? || account == ''
      ret_val = 'Account name required.'
      return
    end
    
    table = SteemApi::Vo::FillVestingWithdraw.arel_table
    all = SteemApi::Vo::FillVestingWithdraw.where(table[:from_account].not_eq(table[:to_account]))
    powerups = if account =~ /%/
      all.where(table[:to_account].matches(account))
    else
      all.where(to_account: account)
    end
    
    if powerups.none?
      ret_val = "No match."
    else
      to = powerups.pluck(:to_account).uniq.join(', ')
      ret_val = "Powerups grouped by sum to #{to} ...\n"
      ret_val += JSON.pretty_generate(powerups.group(:from_account).
        order('sum_try_parse_replace_withdrawn_vests_as_float').
        sum("TRY_PARSE(REPLACE(withdrawn, ' VESTS', '') AS float)"))
    end
  end
  
  def transfers(account)
    ret_val = ""
    exchanges = %w(bittrex poloniex openledger blocktrades)
    
    if account.nil? || account == ''
      ret_val = 'Account name required.'
      return
    elsif exchanges.include? account
      ret_val = 'That procedure is not recommended.'
      return
    end
    
    all = SteemApi::Tx::Transfer.where(type: 'transfer')
    transfers = all.where(to: exchanges)
    transfers = if account =~ /%/
      table = SteemApi::Tx::Transfer.arel_table
      transfers.where(table[:from].matches(account))
    else
      transfers.where(from: account)
    end
    crosscheck_transfers = all.where(memo: transfers.select(:memo))
    
    if transfers.none?
      ret_val = "No match."
    else
      from = transfers.pluck(:from).uniq.join(', ')
      ret_val = "Accounts grouped by transfer count using common memos as #{from} on common exchanges ...\n"
      ret_val += JSON.pretty_generate(crosscheck_transfers.group(:from).order('count_all').count(:all))
    end
  end
  
  def vesting_from(account)
    ret_val = ""
    
    if account.nil? || account == ''
      ret_val = 'Account name required.'
      return
    end
    
    table = SteemApi::Tx::Transfer.arel_table
    all = SteemApi::Tx::Transfer.where(type: 'transfer_to_vesting')
    transfers = all.where(table[:from].not_eq(:to))
    transfers = transfers.where.not(to: '')
    transfers = if account =~ /%/
      table = SteemApi::Tx::Transfer.arel_table
      transfers.where(table[:from].matches(account))
    else
      transfers.where(from: account)
    end
    
    if transfers.none?
      ret_val = "No match."
    else
      from = transfers.pluck(:from).uniq.join(', ')
      ret_val = "Accounts grouped by vesting transfer count from #{from} ...\n"
      ret_val += JSON.pretty_generate(transfers.group(:to).order('count_all').count(:all))
    end
  end
  
  def vesting_to(account)
    ret_val = ""
    
    if account.nil? || account == ''
      ret_val = 'Account name required.'
      exit
    end
    
    table = SteemApi::Tx::Transfer.arel_table
    all = SteemApi::Tx::Transfer.where(type: 'transfer_to_vesting')
    transfers = all.where(table[:from].not_eq(table[:to]))
    transfers = transfers.where.not(to: '')
    transfers = if account =~ /%/
      table = SteemApi::Tx::Transfer.arel_table
      transfers.where(table[:to].matches(account))
    else
      transfers.where(to: account)
    end
    
    if transfers.none?
      ret_val = "No match."
    else
      from = transfers.pluck(:to).uniq.join(', ')
      ret_val = "Accounts grouped by vesting transfer count to #{from} ...\n"
      ret_val += JSON.pretty_generate(transfers.group(:from).order('count_all').count(:all))
    end
  end
end
