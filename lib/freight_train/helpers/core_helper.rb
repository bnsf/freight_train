module FreightTrain::Helpers::CoreHelper
  
  class ListBuilder

    def initialize(sym, template, options)
      @sym, @template, @options = sym, template, options
    end
    
    def headings(*args, &block)
      @template.concat "<tr class=\"row\">\n"
      if block_given?
        yield
      elsif args.length > 0
        args.each {|heading| @template.concat "<th>#{heading}</th>"}
      end
      @template.concat "<th></th></tr>\n"
    end
    
    def creator(*args, &block)
      raise ArgumentError, "Missing block" unless block_given?
      new_record = args.first || @template.instance_variable_get("@#{@sym}")
      
      @template.concat "<tr id=\"add_row\" class=\"row editor new\">"
      @template.fields_for new_record, &block
      @template.concat "</tr>"
    end
    
    def editor(*args, &block)
      raise ArgumentError, "Missing block" unless block_given?
      options = args.extract_options!
      builder = FreightTrain::Builders::InlineFormBuilder.default_inline_editor_builder
 
      #@after_init_edit = "" # if !@after_init_edit
      @template.instance_variable_set("@after_init_edit", "")
      @template.instance_variable_set("@inline_editor", @template.capture do
        yield builder.new( @sym, nil, @template, options, block)
      end)
      #@template.instance_variable_set("@after_init_edit", @after_init_edit)
    end
    
  end
  
  def list( *args, &block )
    options = args.extract_options!    
    table_name = args.last.to_s
    raise ArgumentError, "Missing table name" unless table_name.length > 0
    model_name = table_name.classify
    instance_name = table_name.singularize
    
    records = instance_variable_get "@#{table_name}"
    path = options[:path] || polymorphic_path(args)

    # put everything inside a form
    concat "<form class=\"freight_train\" model=\"#{model_name}\" action=\"#{path}\" method=\"get\">"
    concat "<input name='#{request_forgery_protection_token}' type='hidden' value='#{escape_javascript(form_authenticity_token)}'/>\n"
    concat "<input name='originating_controller' type='hidden' value='#{controller_name}'/>\n"
    
    #if( options[:partial] )

    # table
    concat "<table class=\"list\">\n<thead>\n"
    
    if block_given?

      yield ListBuilder.new(instance_name, self, options)    

    else
    
    end

    # show records
    concat "</thead>\n<tbody id=\"#{table_name}\">\n"
    concat render(:partial => instance_name, :collection => records) unless !records or (records.length==0)
    concat "</tbody>\n"
    concat "</table>\n"
    concat "</form>\n"
    
    if options[:paginate]
      #concat "<tfoot>"
      concat will_paginate(records).to_s
      #concat "</tfoot>"
    end

    # generate javascript
    make_interactive path, table_name, options
  end


private


end