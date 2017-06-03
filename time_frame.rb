require 'rubygems' 
require 'date'
require "ftools"
#require 'FileUtils'

class TimeFrame
  
  def self.get_time_frame (input_values)
    
    puts input_values.inspect
    finish_date = Date.today-input_values[2].to_i
    time_interval = input_values[3].to_i-1
    start_date = finish_date - time_interval
    puts "name is #{input_values[0]} #{input_values[1]}"
    puts "start_date is #{start_date}"
    puts "finish_date is #{finish_date}"

    directory = "#{start_date} to #{finish_date}" 
    File.makedirs(directory)
#    File.move directory, "../#{directory}"
    return start_date, finish_date
  end

end
