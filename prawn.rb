require 'rubygems'
require 'prawn/core'
require 'prawn/layout'

class GeneratePDF
    
  def self.print_pdf(updated_status_data, project_hash, start, finish, name, old_status_data)
    project_hash.keys.each do |project|
      foo = ReadProjectData.new.get(project) 
      if foo
        status_field = updated_status_data["#{project}"]
        pdf_doc_filename = status_field["Project Name"]
        Prawn::Document.generate(
                                 "#{pdf_doc_filename} " + 
                                 "Report #{start} to #{finish}.pdf",
                                 :page_size => "A4"
                                 ) do |pdf|
          pdf.font("Times-Roman")
          logo = "codefire.png"
          pdf.image("#{logo}", :width => 200)
          pdf.pad(20) do
            pdf.text "Document Information", :size => 16, :style => :bold
          end
          
          heading = [ [ {:text => "Client", :font_style => :bold}, 
                        {:text => "#{status_field["Client Name"]}", :colspan => 4 }], 
                      [ {:text => "Project", :font_style => :bold}, 
                        {:text => "#{project}", :colspan => 4 }], 
                      [ {:text => "Description", :font_style => :bold}, 
                        {:text => "Project Hours for#{format_date(start.inspect)} to#{format_date(finish.inspect)}", :colspan => 4 }], 
                      [ {:text => "Author", :font_style => :bold}, {:text => "#{name[0]} #{name[1]} ", :colspan => 4 }] ]
          
          pdf.table heading, 
          :border_style => :grid, #:underline_header 
          :font_size => 12, 
          :horizontal_padding => 6, 
          :vertical_padding => 1, 
          :border_width => 0.3, 
          :column_widths => { 0 => 130, 1 => 100, 2 => 100, 3 => 100, 4 => 80 }, 
          :position => :left, 
          :align => { 0 => :left, 1 => :left, 2 => :left}#, 3 =>  :right, 4 => :right } 
          
          pdf.pad(20) do
            pdf.text "Work Summary", :size => 16, :style => :bold
          end
          
         cap_minus_ten = ((status_field["Cap"].to_f)-(status_field["Target"].to_f.round(2))*0.1)
          
          if status_field["Charged (y\/n)"] == "y"
            invoice_amount = (project_hash[project][:project_hours].to_f*status_field["Hourly Rate"].to_f).round(2)
            if invoice_amount + old_status_data[project]["Billed"].to_f > cap_minus_ten && cap_minus_ten > 0
            then 
              invoice_amount = (cap_minus_ten - old_status_data[project]["Billed"].to_f).round(2)
              hit_cap = 1
              status_field["Charged (y\/n)"] = "n"
            else
              hit_cap = 0
            end
          else
            invoice_amount = 0
          end

          pdf.pad(0) do
            pdf.text "Development time spent on project #{project} from#{format_date(start.inspect)} to#{format_date(finish.inspect)}", :size => 12
            if hit_cap == 1
              pdf.text "Note: The amount billed for #{project} this cycle has been adjusted as the project has hit cap.
              The remaining 10% will become due upon signoff of the final delivery."
            end
          end
          
          pdf.pad(20) do
            pdf.text "Time Report", :size => 16, :style => :bold
          end
          
          pdf.font_size 35 
          pdf.bounding_box([230,750], :width => 250) do
            pdf.text "Client Report"
          end        
          
          ticket_list = Array.new
          project_hash[project][:tracker_arrays].each do |issue|
            stripped = "#{issue[:ticket_array]}".gsub('<br>', '')
            ticket_list << "#{stripped}"
          end
          if project_hash[project][:hours_unnassigned].to_i > 0
            ticket_list << "Design (#{project_hash[project][:hours_unnassigned]}hrs)\n"
          end
          if project_hash[project][:proj_management].to_f > 0 
            ticket_list << "Project Management (#{project_hash[project][:proj_management].to_f.round(2)}hrs)\n\n"
          else
            ticket_list << "\n"
          end

          total_hours_invoiced = status_field["Time Spent"].to_f*status_field["Hourly Rate"].to_f
          if total_hours_invoiced > cap_minus_ten + status_field["Target"].to_f*0.1
          then total_hours_invoiced = cap_minus_ten + status_field["Target"].to_f*0.1
          end
          
          double_lines = [{:text => "", :border_width => 0.0}, 
                          {:text => "", :border_width => 0.0}, 
                          {:text => "", :border_width => 0.0}]
          
          if invoice_amount > 0
            puts "here is the invoice amount for #{project} #{invoice_amount}"
            if status_field["Target"].to_f > 0
              billable_row = [{:text => "Billable Hours To Date", :colspan => 4}, 
                              {:text => "#{status_field["Time Spent"]}", :colspan => 4}, 
                              {:text => "#{to_currency(total_hours_invoiced)}", :colspan => 4}]
              
              total_cost_row = [{:text => "Project Total Cost To Date", :colspan => 4}, 
                                {:text => "", :colspan => 4}, 
                                {:text => "#{to_currency(status_field["Billed"])}", 
                                  :colspan => 4}]
              
              target_row = [{:text => "Project Target Cost", :colspan => 4}, 
                            {:text => "", :colspan => 4}, 
                            {:text => "#{to_currency(status_field["Target"])}", :colspan => 4}]
              
              if status_field["Target"].to_f < status_field["Cap"].to_f
                cap_cost_row = [{:text => "Project Cap Cost", :colspan => 4}, 
                                {:text => "", :colspan => 4}, 
                                {:text => "#{to_currency(status_field["Cap"])}", :colspan => 4}]
              else
                cap_cost_row = double_lines
              end
            else
              billable_row = double_lines
              total_cost_row = double_lines
              target_row = double_lines
              cap_cost_row = double_lines
            end 
            
            if status_field["Deposit"].to_f > 0
              deposit_row = [{:text => "Project Deposit", :colspan => 4}, 
                             {:text => "", :colspan => 4}, 
                             {:text => "#{to_currency(status_field["Deposit"])}", :colspan => 4}]
            else
              deposit_row = double_lines
            end
          else          
            billable_row = double_lines
            total_cost_row = double_lines
            target_row = double_lines
            cap_cost_row = double_lines
            deposit_row = double_lines
          end        
          
          pdf.move_down(240)
          
          data = [ [{:text => "#{ticket_list}", :colspan => 4}, 
                    {:text => "#{project_hash[project][:project_hours]}", :colspan => 4 },
                    {:text => "#{to_currency(invoice_amount)}", :colspan => 4}],      
                   double_lines,
                   [{:text => "Invoice amount (billed @$#{status_field["Hourly Rate"].to_f.round(2)}\/hr)", 
                      :colspan => 4}, 
                    {:text => "#{project_hash[project][:project_hours].to_f.round(2)}", :colspan => 4}, 
                    {:text => "#{to_currency(invoice_amount)}", :colspan => 4}],
                   double_lines,
                   billable_row, 
                   double_lines,
                   deposit_row,
                   double_lines,
                   total_cost_row,
                   double_lines,
                   target_row,
                   double_lines,
                   cap_cost_row]
          pdf.table data, 
          :header => :true,
          :headers => [ {:text => "Time Spent on #{project}", :font_style => :bold, :colspan => 4}, 
                        {:text => "Billable Hours", :font_style => :bold, :colspan => 4 },
                        {:text => "Cost (ex)", :font_style => :bold, :colspan => 4}],
          :align_headers => :center,
          :border_style => :grid, #:underline_header 
          :font_size => 12, 
          :horizontal_padding => 6, 
          :vertical_padding => 1, 
          :border_width => 0.3, 
          :column_widths => {0 => 350, 1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 1, 6 => 25, 7 => 50, 8 => 70}, 
          :position => :left, 
          :align => { 0 => :left, 3 => :right, 4 => :center, 5 => :center} 
          
          pdf.font_size 10 
          #          pdf.text "#{pdf_doc_filename}" + " by #{name.to_s}"
          #pdf.text "new data = #{status_field.inspect}"
          #pdf.text "old data = #{old_status_data["#{project}"].inspect}"
          #          pdf.text "Redmine Info"
          #          pdf.text "#{project_hash[project].inspect}"
        end
      end
    end 
  end
  
  private

  def self.format_date(date)
    d = date.to_s.split(//)
    d = d.slice(4..d.size)
    return d
  end

  def self.to_currency(string)
    t = "%0.2f" % string.to_f
    t = t.to_s.split(//)
    if t.size > 6
      t = t.insert(-7, ",")
    end
    t = "$#{t}"
    return t
  end  
  
end

