class ChartsController < ApplicationController
  def index
  end
  
  def net_transfers
    @account_name = params[:account_name]
    @days = (params[:days] || '14').to_i
    
    @bids = SteemApi::Tx::Transfer.where(to: @account_name)
    @bids = @bids.where('timestamp > ?', @days.day.ago)
    @bids = @bids.where('memo LIKE ?', '%@%')
    @bids = @bids.group_by{ |b| b.timestamp.to_date.to_s(:db) }

    @refunds = SteemApi::Tx::Transfer.where(from: @account_name)
    @refunds = @refunds.where('timestamp > ?', @days.day.ago)
    @refunds = @refunds.where('memo LIKE ?', '%ID:%')
    @refunds = @refunds.group_by{ |b| b.timestamp.to_date.to_s(:db) }
    
    @net_transfers = @bids.map do |k, v|
      refunds = [@refunds[k]].flatten.compact
      refund_sum = refunds.map(&:amount).sum; [k, v.map(&:amount).sum - refund_sum]
    end
  end
end