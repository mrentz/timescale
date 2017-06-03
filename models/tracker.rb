class Tracker < ActiveRecord::Base
has_many :issues
has_many :time_entries
has_many :projects
end
