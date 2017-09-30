class ChartsController < ApplicationController
  def index
  end
  
  def net_transfers
    @compare_to = params[:compare_to]
    @account_name = params[:account_name]
    @days = (params[:days] || '14.0').to_f
    @symbol = params[:symbol] || 'SBD'
    @average = 0
    
    @net_transfers = build_net_transfers(@account_name, @symbol, @days)
    @days = [@net_transfers.size, @days].min
    @average = if @days == 0
      0
    elsif @days < 2
      @net_transfers.map{ |k, v| v }.sum / (@days * 24)
    else
      @net_transfers.map{ |k, v| v }.sum / @days
    end
    
    if @compare_to.present?
      @compare_to_net_transfers = build_net_transfers(@compare_to, @symbol, @days)
      @compare_to_average = if @days == 0
        0
      elsif @days < 2
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
    @symbol = params[:symbol] || 'SBD'
    
    @net_transfers = build_day_of_the_week(@account_name, @symbol, @days)
    
    if @compare_to.present?
      @compare_to_net_transfers = build_day_of_the_week(@compare_to, @symbol, @days)
    end
    
    @composite = [
      {name: @account_name, data: @net_transfers},
      {name: @compare_to, data: @compare_to_net_transfers}
    ]
  end
private
  def build_net_transfers(account_name, symbol, days)
    bids = SteemApi::Tx::Transfer.where(to: account_name, amount_symbol: symbol)
    bids = bids.where('timestamp > ?', days.day.ago)
    bids = bids.where('memo LIKE ?', '%@%')
    bids = bids.group_by do |b|
      if days < 2
        b.timestamp.strftime("%H")
      else
        b.timestamp.to_date.to_s(:db)
      end
    end
    
    refunds = SteemApi::Tx::Transfer.where(from: account_name, amount_symbol: symbol)
    refunds = refunds.where('timestamp > ?', days.day.ago)
    refunds = refunds.where('memo LIKE ?', '%ID:%')
    refunds = refunds.group_by do |b|
      if days < 2
        b.timestamp.strftime("%H")
      else
        b.timestamp.to_date.to_s(:db)
      end
    end
    
    bids.map do |k, v|
      refund_sum = [refunds[k]].flatten.compact.map(&:amount).sum
      [k, v.map(&:amount).sum - refund_sum]
    end
  end
  
  def build_day_of_the_week(account_name, symbol, days)
    bids = SteemApi::Tx::Transfer.where(to: account_name, amount_symbol: symbol)
    bids = bids.where('timestamp > ?', days.day.ago)
    bids = bids.where('memo LIKE ?', '%@%')
    bids = bids.group_by do |b|
      b.timestamp.strftime('%w %A')
    end
    
    refunds = SteemApi::Tx::Transfer.where(from: account_name, amount_symbol: symbol)
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
end
