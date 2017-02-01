class PriceHistory
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in collection: 'PriceHistory'
end
