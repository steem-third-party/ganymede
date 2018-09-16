class BlocksController < ApplicationController
  def index
    @transaction_type = params[:transaction_type]
    
    case @transaction_type
    when 'transfer'
      @from = params[:from].presence
      @to = params[:to].presence
      @memo = params[:memo].presence
      
      transfers = SteemApi::Tx::Transfer.all
      transfers = transfers.where(from: @from) if !!@from
      transfers = transfers.where(to: @to) if !!@to
      transfers = transfers.where(memo: @memo) if !!@memo
      
      @transactions = SteemApi::Transaction.where(tx_id: transfers.select(:tx_id)).limit(100)
      @transactions = @transactions.order(expiration: :desc)
    end
  end
end