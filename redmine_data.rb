require 'rubygems' 
require 'active_record'
require "yaml"
require "date"

dbconfig = YAML::load(File.open('database.yml'))
ActiveRecord::Base.establish_connection(dbconfig["production"])

Dir[File.dirname(__FILE__) + "/models/*.rb"].each {|file| require file}



class RedmineData
  
  def self.get_redmine_project_data(start_date, finish_date)
    pm_loading = 1.2
    time_interval = finish_date - start_date 
    project_hash = Hash.new
    puts ""  
    puts "No time entries were entered this billing cycle for"
    Project.all(:order => "name").each do |project|
      ticketed_time = 0
      test =  project.time_entries.find(:all,
                                        :conditions => {:spent_on => start_date..finish_date})
      project_key = Hash.new
      tracker_array = []
      if !test.empty?	 
        project_key[:project_name] = project.name
        project_key[:hours_entered] = test.sum(&:hours).to_f.round(2)
        project_key[:total_hours] = project.time_entries.sum(:hours).round(2)
        Tracker.all.each do |tracker|
          tracker_hash = Hash.new
          time_spent, tickets = time_spent_on_tickets(project_key[:project_name], 
                                                      tracker.id, 
                                                      start_date, finish_date)
          if time_spent > 0
            tracker_hash[:ticket_type] = tracker.name
            if tracker.name == "PMAdmin"
              tracker_hash[:time_spent] = (time_spent).round(2)
            else
              tracker_hash[:time_spent] = (time_spent*pm_loading).round(2)
            end    
            tracker_hash[:ticket_array] = tickets
            ticketed_time += time_spent # used for determining unassigned hours
            tracker_array << tracker_hash
          end
        end
        tracked_time = 0
        tracker_array.each {|time| tracked_time += time[:time_spent]}
        project_key[:time_frame] = time_interval + 1
        project_key[:tracker_arrays] = tracker_array
        project_key[:hours_unnassigned] = (project_key[:hours_entered] - ticketed_time).to_f.round(2)
        project_key[:project_hours] = ((project_key[:hours_unnassigned]*pm_loading+tracked_time)).to_f.round(2)
        project_key[:proj_management] = project_key[:project_hours] - project_key[:hours_entered]
        project_hash[project.name] = project_key
      else
        puts project.name
      end
    end
    puts "\n"
    puts "\n"
    puts "Details for all current time entries having no Operation"
    puts "Status have been printed to \"Outside.html\""
    puts "\n"
    puts "\n"
    return project_hash
  end #def self.get_redmine_project_hash
  
  def self.get_project_id(project_name)
    Project.find(:first, :conditions => {:name => project_name}).id
  end
  
  def self.time_spent_on_tickets(project_name, tracker_id, start_date, finish_date)
    ticketed_time = 0
    time_spent = 0
    issue_ticket_array = []
    Project.find(:first,
                 :conditions => {:id =>
                   get_project_id(project_name)}).issues.find(:all,
                                                              :conditions =>
                                                              {:tracker_id =>
                                                                tracker_id}).each do
      |individual_tracker_issues| # e.g. "bugs" "Features" "todos", etc
      tracker_ticket = 0
      ticketed_time = 0 
      ticket_subject = individual_tracker_issues.subject
      individual_tracker_issues.time_entries.find(:all,
                                                  :conditions =>
                                                  {:spent_on =>
                                                    start_date..finish_date}).each do
        |time|
        ticketed_time += time.hours.round(2)
        time_spent += time.hours
        tracker_ticket = time.issue_id
      end
      if ticketed_time > 0 
        issue_ticket_array << " \##{tracker_ticket} #{ticket_subject} (#{ticketed_time}hrs)\n<br>"
      end
    end
    return time_spent, issue_ticket_array
  end
  
end #RedmineData

