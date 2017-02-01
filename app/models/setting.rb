class Setting
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
store_in collection: 'settings'
end
