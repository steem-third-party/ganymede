class DiscussionsController < ApplicationController
  def index
    @other_promoted = params[:other_promoted].presence || 'false'
    @limit = params[:limit].presence || '2000'
    
    if @other_promoted == 'true'
      @limit = @limit.to_i

      response = api.get_account_history('null', -@limit, @limit)
      history = response.result

      @discussions = history.map do |entry|
        timestamp = Time.parse(entry.last.timestamp + 'Z')
        op = entry.last.op.last
        from = op.from
        memo = op.memo
        amount = op.amount
        
        next if memo.nil? || memo.empty?
        next if memo.include? from

        slug = memo.split('@').last
        author, url = slug.split('/')
        
        {
          slug: slug,
          url: "https://steemit.com/tag/@#{slug}",
          from: from,
          amount: amount,
          timestamp: timestamp,
          # content: api.get_content(author, url).result
        }
      end.reject(&:nil?)
    else
      @discussions = []
    end
  end
end
