class FreightTrain::Builders::RowBuilder
  include FreightTrain::Helpers::RowHelper,
          FreightTrain::Helpers::FormattingHelper,
          ActionView::Helpers::NumberHelper,
          ERB::Util
  
  @@default_row_builder = FreightTrain::Builders::RowBuilder
  def self.default_row_builder; @@default_row_builder; end
  def self.default_row_builder=(val); @@default_row_builder=val; end

  def initialize(template, object_name, record)
    @template = template
    @object_name = object_name
    @record = record
  end

  def currency_of(method)
    number = @record.send method
    string = 
    if( number < 0 )
      "($<span attr=\"#{@object_name}[#{method}]\" value=\"#{number}\">#{number_to_currency -number, :unit=>""}</span>)"
    else
      "$<span attr=\"#{@object_name}[#{method}]\">#{number_to_currency number, :unit=>""}</span>"
    end
  end

  def fields_for(method, &block)
    value = @record.send method
    if value.is_a? Array
      (0...value.length).each do |i|
        #yield @@default_row_builder.new( @template, "#{@object_name}[#{method}][#{i}]", value[i] )
        yield @@default_row_builder.new( @template, "#{@object_name}[#{method}]", value[i] )
      end
    else
      yield @@default_row_builder.new( @template, "#{@object_name}[#{method}]", value )
    end
  end

  def hidden_field(method)
    value = @record.send method
    if value.is_a? Array
      "<span attr=\"#{@object_name}[#{method}]\" value=\"#{value.join("|")}\"></span>"
    else
      "<span attr=\"#{@object_name}[#{method}]\" value=\"#{value}\"></span>"
    end
  end

  def nested_fields_for(method, *args, &block)
    options = args.extract_options!
  
    @template.concat "<table class=\"nested #{options[:hidden]?"hidden":""}\" attr=\"#{@object_name}[#{method}]\""
    #html_options.each{|k,v| @template.concat " #{k}=\"#{v}\""}
    @template.concat ">"
    
    i = 0
    children = @record.send method
    for child in children
      @template.concat "<tr id=\"#{method.to_s.singularize}_#{i}\">"
      yield @@default_row_builder.new( @template, "#{@object_name}[#{method}]", child )
      @template.concat "</tr>"
      i += 1
    end
    @template.concat "</table>"
  end
  
  def text_of(method)
    "<span attr=\"#{@object_name}[#{method}]\">#{h @record.send(method)}</span>"
  end
  
  def toggle_of(method, *args)
    options = args.extract_options!
    value = @record.send method    
    #content = "<input type=\"checkbox\" attr=\"#{method}\" disabled=\"disabled\""
    #content << " checked=\"checked\"" if @record.send method
    #content << " />"
    content = "<div class=\"toggle #{value ? "yes" : "no"}\" attr=\"#{@object_name}[#{method}]\" value=\"#{value}\""
    content << " title=\"#{options[:title]}\"" if options[:title]
    content << "></div>"
  end
  
  def value_of(method, value_method, display_method, *args)
    options = args.extract_options!
    value = @record.send method
    value_value = value ? (value_method ? value.send(value_method) : value) : ""
    value_display = value ? (display_method ? value.send(display_method) : value) : ""
    method = options[:attr] if options[:attr]
    "<span attr=\"#{@object_name}[#{method}]\" value=\"#{value_value}\">#{value_display}</span>"    
  end
  

protected
  
end