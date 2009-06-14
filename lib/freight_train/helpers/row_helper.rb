module FreightTrain::Helpers::RowHelper

  def row_for( record, *args, &block )
    options = args.extract_options!
    
    unless @update_row
      css_class = "row"
      if options[:disabled]
        css_class << " disabled"
      else
        css_class << " interactive editable"
      end
 
      # this makes striping work on IE7 and Firefox 3
      alt = !@template.instance_variable_get("@alt")
      @template.instance_variable_set("@alt", alt)
      css_class << " alt" if !alt
 
      concat "<tr class=\"#{css_class}\" id=\"#{idof record}\">"
    end
    
    name = ActionController::RecordIdentifier.singular_class_name(record)
    yield FreightTrain::Builders::RowBuilder.default_row_builder.new(self, name, record)

    # IE7 doesn't support the CSS selector :last-child, therefore, we do this explicitly
    #concat "<td>#{commands_for(record, options[:commands])}</td>"
    concat "  <td class=\"last-child\">#{commands_for(record, options[:commands])}</td>\n"
    
    concat "</tr>\n" unless @update_row
  end

  def commands_for( record, commands )
    html = ""
    if commands
      html << "<span class=\"commands\">"
      commands.each do |command|
        html << send("#{command}_command_for", record)
      end
      html << "</span>"
    end
    html
  end

  def idof( record )
    "#{record.class.name.underscore}_#{record.id}"
  end


private


  def delete_command_for( record )
    #"<a class=\"delete-command\" href=\"javascript:Generated.delete_item(#{record.id});\">delete</a>"
    # use onclick so that event stops bubbling
    #"<a class=\"delete-command\" href=\"#\" onclick=\"Generated.delete_item(#{record.id});\">delete</a>"
    "<a class=\"delete-command\" href=\"#\" onclick=\"FT.#{record.class.name}.destroy(#{record.id});\">delete</a>"
  end

end