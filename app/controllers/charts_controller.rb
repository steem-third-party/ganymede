class ChartsController < ApplicationController
  def index
  end

  def net_transfers
    @compare_to = params[:compare_to]
    @account_name = params[:account_name]
    @days = (params[:days] || '14.0').to_f
    @symbol = params[:symbol] || default_debt_asset
    @segments = params[:segments] || 'default'
    @average = 0

    if @days < 2 && @segments == 'default'
      @segments = 'hourly'
    end

    @net_transfers = build_net_transfers(@account_name, @symbol, @days, @segments)
    @days = [@net_transfers.size, @days].min unless @segments == 'hourly'
    @average = if @days == 0
      0
    elsif @segments == 'hourly'
      @net_transfers.map{ |k, v| v }.sum / (@days * 24)
    else
      @net_transfers.map{ |k, v| v }.sum / @days
    end

    if @compare_to.present?
      @compare_to_net_transfers = build_net_transfers(@compare_to, @symbol, @days, @segments)
      @compare_to_average = if @days == 0
        0
      elsif @segments == 'hourly'
        @compare_to_net_transfers.map{ |k, v| v }.sum / (@days * 24)
      else
        @compare_to_net_transfers.map{ |k, v| v }.sum / @days
      end
    end

    @composite = [
      {name: @account_name, data: @net_transfers},
      {name: @compare_to, data: @compare_to_net_transfers}
    ]
  end

  def day_of_the_week
    @compare_to = params[:compare_to]
    @account_name = params[:account_name]
    @days = (params[:days] || '14.0').to_f
    @symbol = params[:symbol] || default_debt_asset

    @net_transfers = build_day_of_the_week(@account_name, @symbol, @days)

    if @compare_to.present?
      @compare_to_net_transfers = build_day_of_the_week(@compare_to, @symbol, @days)
    end

    @composite = [
      {name: @account_name, data: @net_transfers},
      {name: @compare_to, data: @compare_to_net_transfers}
    ]
  end

  def accounts_created
    @days = (params[:days] || '14.0').to_f
    @segments = params[:segments] || 'default'
    @average = 0
    @style = params[:style] || 'default'

    if @days < 2 && @segments == 'default'
      @segments = 'hourly'
    end

    @account_creates = account_creates.where('timestamp > ?', @days.day.ago)
    @account_creates = if @segments == 'hourly'
      @account_creates.group("FORMAT(timestamp, 'HH')").order('format_timestamp_hh')
    else
      @account_creates.group('CAST(timestamp AS DATE)').order('cast_timestamp_as_date')
    end
    @account_creates = @account_creates.count(:all)
    @days = @account_creates.size - 1 unless @segments == 'hourly'
    @total = @account_creates.values.sum
    @average = @total / @days

    case @style
    when 'cumlative'
      total = 0
      @account_creates.each do |k, v|
        @account_creates[k] = (total += v)
      end
    end
  end

  def accounts_last_bandwidth_updated
    @days = (params[:days] || '14.0').to_f
    @segments = params[:segments] || 'default'
    @average = 0
    @style = params[:style] || 'default'

    if @days < 2 && @segments == 'default'
      @segments = 'hourly'
    end

    @account_last_bandwidth_updates = accounts.where('last_bandwidth_update > ?', @days.day.ago)
    @account_last_bandwidth_updates = if @segments == 'hourly'
      @account_last_bandwidth_updates.group("FORMAT(last_bandwidth_update, 'HH')").order('format_last_bandwidth_update_hh')
    else
      @account_last_bandwidth_updates.group('CAST(last_bandwidth_update AS DATE)').order('cast_last_bandwidth_update_as_date')
    end
    @account_last_bandwidth_updates = @account_last_bandwidth_updates.count(:all)
    @days = @account_last_bandwidth_updates.size - 1 unless @segments == 'hourly'
    @total = @account_last_bandwidth_updates.values.sum
    @average = @total / @days

    case @style
    when 'cumlative'
      total = 0
      @account_last_bandwidth_updates.each do |k, v|
        @account_last_bandwidth_updates[k] = (total += v)
      end
    end
  end
private
  def build_net_transfers(account_name, symbol, days, segments)
    bids = transfers.where(to: account_name, amount_symbol: symbol)
    bids = bids.where('timestamp > ?', days.day.ago)
    bids = bids.where('memo LIKE ?', '%@%')
    bids = bids.group_by do |b|
      if segments == 'hourly'
        b.timestamp.strftime("%H")
      else
        b.timestamp.to_date.to_s(:db)
      end
    end

    refunds = transfers.where(from: account_name, amount_symbol: symbol)
    refunds = refunds.where('timestamp > ?', days.day.ago)
    refunds = refunds.where('memo LIKE ?', '%ID:%')
    refunds = refunds.group_by do |b|
      if segments == 'hourly'
        b.timestamp.strftime("%H")
      else
        b.timestamp.to_date.to_s(:db)
      end
    end

    bids.sort_by{ |k, v| k }.map do |k, v|
      refund_sum = [refunds[k]].flatten.compact.map(&:amount).sum
      [k, v.map(&:amount).sum - refund_sum]
    end
  end

  def build_day_of_the_week(account_name, symbol, days)
    bids = transfers.where(to: account_name, amount_symbol: symbol)
    bids = bids.where('timestamp > ?', days.day.ago)
    bids = bids.where('memo LIKE ?', '%@%')
    bids = bids.group_by do |b|
      b.timestamp.strftime('%w %A')
    end

    refunds = transfers.where(from: account_name, amount_symbol: symbol)
    refunds = refunds.where('timestamp > ?', days.day.ago)
    refunds = refunds.where('memo LIKE ?', '%ID:%')
    refunds = refunds.group_by do |b|
      b.timestamp.strftime('%w %A')
    end

    bids.sort_by{ |k, v| k }.map do |k, v|
      refund_sum = [refunds[k]].flatten.compact.map(&:amount).sum
      [k.split(' ').last, v.map(&:amount).sum - refund_sum]
    end

  end

  def default_debt_asset
    if steemit?
      'SBD'
    elsif golos?
      'GBG'
    end
  end

  def transfers
    if steemit?
      SteemApi::Tx::Transfer
    elsif golos?
      GolosCloud::Tx::Transfer
    end
  end

  def account_creates
    if steemit?
      SteemApi::Tx::AccountCreate
    elsif golos?
      GolosCloud::Tx::AccountCreate
    end
  end

  def accounts
    if steemit?
      SteemApi::Account
    elsif golos?
      GolosCloud::Account
    end
  end
end
