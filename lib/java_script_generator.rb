class ActionView::Helpers::PrototypeHelper::JavaScriptGenerator

  def refresh( mode, record, *args )
    case mode
    when :single
      refresh_record record, *args
    else
      refresh_records record.class, *args
    end
  end
  
  def add_record( record, *args )
    options = args.extract_options!
    model_name = record.class.name
    partial_name = record.class.name.underscore
    insert_html  :top,
                 record.class.name.tableize,
                 :partial => (options[:partial] || ((ocn=options[:originating_controller]) ? "/#{ocn}/#{partial_name}" : partial_name)),
                 :object => record
    @lines << "FT.hookup_row('#{model_name}',$('#{idof record}'));"
    call "FT.restripe_rows"
  end

  def refresh_record( record, *args )
    options = args.extract_options!
    id = idof record
    model_name = record.class.name
    partial_name = record.class.name.underscore
    replace_html id,
                 :partial => (options[:partial] || ((ocn=options[:originating_controller]) ? "/#{ocn}/#{partial_name}" : partial_name)),
                 :object => record
                 #:locals => {:single => true}
    @lines << "FT.hookup_row('#{model_name}',$('#{id}'));"
  end

  def refresh_records( model, *args )
    options = args.extract_options!
    collection = args.first || model
    model_name = model.name
    table_name = model_name.tableize
    partial_name = model_name.underscore
    replace_html table_name,
                 :partial => (options[:partial] || ((ocn=options[:originating_controller]) ? "/#{ocn}/#{partial_name}" : partial_name)),
                 :collection => collection.find(:all, (options[:find]||{}) )
    @lines << "$('#{table_name}').select('.row').each(function(row){FT.hookup_row('#{model_name}',row);});"
  end

  def show_error( message )
    replace_html "error", message
    show "error"
  end
  
end