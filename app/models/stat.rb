class Stat
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  store_in collection: 'stats'
end
