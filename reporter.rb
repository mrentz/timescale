require 'rubygems' 
require 'active_record'
require "yaml"
require "project_data"
require 'rubygems'
require "redmine_data"
require "print_html"
require "update_status_data"
require "time_frame"
require "prawn"

total_hours = TimeEntry.all.inject(0) {|sum, e| sum += e.hours}

input_values=[]    
ARGV.each do|a|
  input_values << a
end

status_data = {}
old_status_data = {}
redmine_data = {}
updated_status_data = {}
begin
  start_date, finish_date = TimeFrame.get_time_frame(input_values)
  redmine_data = RedmineData.get_redmine_project_data(start_date, finish_date)
  status_data = RetrieveProjectStatus.new.retrieve_status_file # (redmine_data)
  updated_status_data = UpdateStatusData.compute(status_data, redmine_data)
rescue
  puts $!
  puts $!.backtrace
end
WriteProjectData.write_to_file(updated_status_data)
PrintHTML.print_as_html(redmine_data, start_date, finish_date, total_hours)


GeneratePDF.print_pdf(updated_status_data, 
                      redmine_data, 
                      start_date, 
                      finish_date,
                      input_values,
                      status_data)
         
