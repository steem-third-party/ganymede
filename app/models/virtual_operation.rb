class VirtualOperation
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
store_in collection: 'VirtualOperations'
end
