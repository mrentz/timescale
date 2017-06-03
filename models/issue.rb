class Issue < ActiveRecord::Base
  belongs_to :tracker
  has_many :time_entries
end
