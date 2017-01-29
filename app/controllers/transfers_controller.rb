class TransfersController < ApplicationController
  def index
    @account = params[:account].presence || nil
    @transfers = []
    
    if !!@account
      response = api_execute(:get_account_history, @account, 2000, 2000)
      response.result.each do |history|
        next unless history.last.op.first == 'transfer'
        op = history.last.op.last
        
        @transfers << {
          trx_id: history.last.trx_id,
          timestamp: Time.parse(history.last.timestamp + 'Z'),
          from: op.from,
          to: op.to,
          amount: op.amount,
          memo: op.memo
        }
        
        respond_to do |format|
          format.html { render 'index', layout: action_name != 'card' }
          format.atom { render layout: false }
          format.rss { render layout: false }
        end
      end
    end
  end
end
