require 'rubygems' 
require 'active_record'
require "yaml"
require "project_data"
require "redmine_data"

class PrintHTML
  
  def self.print_as_html(project_hash, start_date, finish_date, total_hours) 
    write_text_file_heading_text(project_hash, start_date, 
                                 finish_date, total_hours, "results.html") 
    write_text_file_heading_text(project_hash, start_date, 
                                 finish_date, total_hours, "outside.html") 
    
    project_hash.sort_by{|key| key[0].downcase}.each do |project|
      foo = ReadProjectData.new.get(project[0]) 
      if foo
        print_results(project_hash, start_date, finish_date, total_hours, "results.html", foo, project)
      else
        print_results(project_hash, start_date, finish_date, total_hours, "outside.html", foo, project)
      end # foo
    end # project sort do
    puts ""
  end # print_as_html 
  
  private
  
  def self.print_results(project_hash, start_date, finish_date, total_hours, file_name, foo, project)
    File.open(file_name, 'a') { |f1|
      f1 << "<b>#{project[0]}</b>\n<br>"
      f1 << "Total project hours to date: #{project[1][:total_hours]} (#{project[1][:total_hours]*1.2} Billable)\n<br>"
      f1 << "#{project[1][:hours_entered]} hours were entered over the #{project[1][:time_frame]} day period, "
      f1 << "#{project[1][:project_hours]} billable\n<br><br>"
      project[1][:tracker_arrays].each do |issue|
        f1 << "#{issue[:time_spent]} hours on #{issue[:ticket_type]}s\n<br>#{issue[:ticket_array]}\n<br>"
      end # tracker_arrays
      if project[1][:hours_unnassigned] > 0
        f1 << "Hours unnassigned, Design (#{project[1][:hours_unnassigned]})\n<br>"
      end # hours_unnasigned
      f1 << "Project Management (#{project[1][:proj_management]})\n<br>"
      f1 << "\n<br>"
      if foo
        f1 << "#{foo.inspect unless nil}\n<br><br>"
      else
        f1 << "#{project[0]} has no \"Operational Status\"\n<br><br>"  
        puts project[0]   
      end # if foo
    }
  end 
  
  def self.write_text_file_heading_text(project_hash, start_date, 
                                        finish_date, total_hours, file_name)    
    File.open(file_name, 'w') { |f1|
      f1 << "\n<br><br><br>Todays date is #{Date.today}\n<br>"
      f1 << "Date reporting from (and including) #{start_date} to #{finish_date}\n<br>"
      f1 << "There are #{Project.all.size}"
      f1 << " projects currently listed on Redmine\n<br>"
      f1 << "#{total_hours.round(2)} hours were spent on all projects\n<br>\n"
      f1 << "<p style=\"white-space:nowrap\">"
    }
  end      
  
end #class
