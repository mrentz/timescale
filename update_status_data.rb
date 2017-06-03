require 'rubygems' 

class UpdateStatusData
  
  def self.compute(status_data, project_hash)
    updated_status_data = {}
    status_data.keys.each do |project|
      project_name = {}
      status_data[project].keys.each do |element|
        project_name[element] = status_data[project][element]
      end
      updated_status_data[project] = project_name
    end
    updated_status_data = update_project_hours(updated_status_data, project_hash)
    updated_status_data = update_date(updated_status_data)
    updated_status_data = update_amount_billed(updated_status_data, project_hash) 
  end
  
  def self.update_project_hours(updated_status_data, project_hash)
    updated_status_data.keys.each do |project|
      if project_hash[project]
      updated_status_data[project]["Time Spent"] = updated_status_data[project]["Time Spent"].to_f.round(2) + 
        project_hash[project][:project_hours]
      end # if project
    end # project do
    return updated_status_data
  end # update_project_hours
  
  def self.update_date(status_data)
    status_data.keys.each do |project|
        status_data[project]["Updated On"] = Date.today
    end# do |project|
    return status_data
  end  # end update_date
  
  def self.update_amount_billed(status_data, project_hash)
    status_data.keys.each do |project|      
      if project_hash[project]
        current_invoice_ammount = project_hash[project][:project_hours].to_f * 
          status_data[project]["Hourly Rate"].to_f
        if status_data[project]["Billed"]
        total_amount_billed = status_data[project]["Billed"].to_f + 
          current_invoice_ammount
        else
          total_amount_billed = status_data[project]["Deposit"].to_f +
            current_invoice_ammount
        end
      else
        total_amount_billed = status_data[project]["Billed"].to_f      
      end #end if project
      if status_data[project]["Charged (y\/n)"] == "y"
        if status_data[project]["Cap"] && 
            total_amount_billed.to_f < ((status_data[project]["Cap"].to_f)-(status_data[project]["Target"].to_f.round(2))*0.1)
               status_data[project]["Billed"] = total_amount_billed.to_f.round(2)
        elsif status_data[project]["Cap"].nil?
          status_data[project]["Billed"] = total_amount_billed
        else
          status_data[project]["Billed"] = (status_data[project]["Cap"].to_f.round(2))-(status_data[project]["Target"].to_f.round(2))*0.1 
#          status_data[project]["Charged (y\/n)"] = "n" -- this code has been added to prawn.rb
        end # if *0.9
      end #if project is billed
      status_data[project]["Effective Rate"] = status_data[project]["Billed"].to_f/status_data[project]["Time Spent"].to_f
    end # do |project|
    return status_data
  end # update_project_hours
  
  def self.current_amount(status_data, project_hash)
    status_data.keys.each do |project|      
      if project_hash[project]
        current_invoice_ammount = project_hash[project][:project_hours].to_f * 
          status_data[project]["Hourly Rate"].to_f
        total_amount_billed = status_data[project]["Billed"].to_f + 
          current_invoice_ammount
      else
        total_amount_billed = status_data[project]["Billed"].to_f      
      end
    end
    return current_invoice_ammount, total_amount_billed 
  end
  
end # UpdateStatusData
