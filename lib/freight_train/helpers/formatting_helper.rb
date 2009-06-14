module FreightTrain::Helpers::FormattingHelper

  def number_to_currency(number, options={})
    if( number < 0 )
      "(#{super -number, options})"
    else
      super(number, options)
    end
  end

  def format_params( hash=params, level=0 )
    output = ""
    hash.map do |k,v|
      level.times do
        output << " "
      end
      if v.is_a? Hash
        output << "#{k}:\n"
        output << format_params(v, level + 2) if v.is_a? Hash
      elsif v.is_a? Array
        output << "#{k}=[#{v.join(",")}]\n"
      else
        output << "#{k}='#{v}'\n"
      end
    end
    output
  end

  def format_errors( object )
    if object and object.respond_to? "errors"
      temp = "<ul>"
      object.errors.each do |k,v|
        temp << "<li>"
        temp << "<p>#{k.humanize} #{v}</p>"
        if object.respond_to? k
          value = object.send k
          temp << format_errors(value)
        end
        temp << "</li>"
      end
      temp << "</ul>"
    else
      ""
    end
  end

  def format_exception_for(record, options={})
    "<p>An error occurred while trying to #{options[:action]} #{record.class.name.titleize}:</p><ul><li>#{h $!}</li></ul>"
  end

end