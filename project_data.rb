require 'rubygems'
require 'fastercsv'

class ReadProjectData
  
  def get(project_name = "")
    project = fetch_project_from_file project_name
    return project.to_hash if project
  end

  private

  def fetch_project_from_file(project_name = "")
    file = FasterCSV.read('operation_status.csv', :headers => true) #rescue nil
    return file.detect {|row| row["Project Name"] == project_name} #if file
  end

end

class WriteProjectData
  
  def self.write_to_file(status_file_converted_to_hash)
    headings = Array.new
    headings = column_headings
    FasterCSV.open("operation_status.csv", "w", {:col_sep =>',', :row_sep =>:auto, :headers => true, :return_headers => false}) do |csv|
      csv << (headings.each {|element| element})
      status_file_converted_to_hash.sort_by{|key| key[0].downcase}.each do |project_row|
        if project_row
          csv << (headings.map {|element| project_row[1][element]})
        end
      end 
    end
  end

  private

  def self.column_headings
    file = FasterCSV.read('operation_status.csv', :headers => true).headers
  end

 end

class RetrieveProjectStatus
  
  def retrieve_status_file
    projects_status = Hash.new
    status_array = []
    FasterCSV.foreach("operation_status.csv", :headers => true) do |row|
      status_array << row[0]
    end # do row
    status_array.each do |project| 
      j = ReadProjectData.new.get(project)
      if j
        projects_status[project]=j
      end # if
    end # do project
    return projects_status
  end

end

class RetrieveProjectStatus_orig
  
  def retrieve_status_file(project_hash)
    projects_status = Hash.new
    project_hash.keys.each do |project| 
      j = ReadProjectData.new.get(project)
      if j
        projects_status[project]=j
      end
     end
    return projects_status
  end

end


#projects = Hash.new
#projects[:realives] = ReadProjectData.new.get("Realives")
#
#if projects[:realives]["Charged (y\/n)"] == "y"
#puts projects[:realives]["Charged (y\/n)"]
#end
#
#projects[:"Exp Plus Stage 1"] = ReadProjectData.new.get("Exp Plus Stage 1")
##puts projects[:realives]["Billed"]
#WriteProjectData.new.write_to_file(projects)
