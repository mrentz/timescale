class Project < ActiveRecord::Base

  has_many :issues
  has_many :trackers
  has_many :time_entries do
    def for(options = {})
      #self.find(:all, :conditions => )
    end
  end

end
