class TimeEntry < ActiveRecord::Base
belongs_to :issue
belongs_to :tracker
end
