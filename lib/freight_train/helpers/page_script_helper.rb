module FreightTrain::Helpers::PageScriptHelper

  def make_interactive( path, table_name, options )
    options[:destroy] = true unless options.key?(:destroy)

    concat "<script type=\"text/javascript\">\n" << 
           "//<![CDATA[\n"

           # create a namespace for record-specific functions
    concat "FT.#{table_name.classify}=(function(){\n" <<
           "  var path='#{path}';\n" <<
           "  var obsv=new Observer();\n"

    if @inline_editor
      concat "  var editor_writer=#{editor_writer_method(options)};\n"
      concat "  InlineEditor.observe('after_init',#{after_edit_method(options)});\n"
    end

    concat "  return {\n" <<
           "    path: function(){return path;},\n" <<
           "    observe: function(n,f){obsv.observe(n,f);},\n" <<
           "    unobserve: function(n,f){obsv.unobserve(n,f);},\n" <<
           "    update_in_place: function(property,id,value){FT.xhr((path+'/'+id+'/update_'+property),'put',('#{table_name.singularize}['+property+'='+value));},\n"
    concat "    #{destroy_method(table_name, options)},\n" if options[:destroy]
    concat "    #{hookup_row_method options}\n" <<
           "  };\n" <<
           "})();\n"

    # methods in global namespace
    if options[:reset_on_create] != :none
      options[:reset_on_create] = :all unless options[:reset_on_create].is_a?(Array)
      concat reset_on_create_method(table_name, options) << "\n"
    end

    concat "//]]>\n" <<
           "</script>\n"
    @already_defined = true
  end

  # move as much of this as possible to core.js
  def ft_init(options={})
    unless @already_initialized
      concat "<script type=\"text/javascript\">\n" << 
             "//<![CDATA[\n" <<
             "FT.init({"
      # options go here
      concat   "token: '#{request_forgery_protection_token}='+encodeURIComponent('#{escape_javascript(form_authenticity_token)}')" <<
             "});\n" <<
             "//]]>\n" <<
             "</script>\n"
      @already_initialized = true
    end
  end

private

  def destroy_method( table_name, options )
    msg = options[:confirm] || "Delete #{table_name.to_s.singularize.titleize}?"
    "destroy: function(idn){" <<
      "FT.destroy('#{msg}',('#{table_name.to_s.singularize}_'+idn),(path+'/'+idn));" <<
    "}"
  end
  
  def hookup_row_method( options )
    content = "hookup_row: function(row){"
    if @inline_editor
      content << "if(row.hasClassName('editable')) FT.edit_row_inline(row,path,editor_writer);"
    elsif (options[:editable] != false)
      content << "if(row.hasClassName('editable')) FT.edit_row(row,path);"
    end
    content << "obsv.fire('hookup_row',row);"
    content << "}"
  end

  def reset_on_create_method( table_name, options )
    arg = options[:reset_on_create]
    content =  "FT.observe('created',function(){" <<
                 "$$('form[model=\"#{table_name.classify}\"]').each(function(form){"
    if arg == :all
      content <<   "form.reset();"
    else
      content <<   "var e;"
      arg.each{|id| content << "e=form.down('##{id}');if(e)e.value='';"}
    end
    
    # make this intuitive
    content <<     "form.select('#add_row table.nested.editor').each(FT.reset_nested);" if @enable_nested_records
    content <<   "});" <<
               "});"
  end
  
  def editor_writer_method( options )
    "function(tr){" <<  
      "var e;" <<
      "var html='" << @inline_editor.gsub(/\r|\n/, "") << "';" <<
      "return html;" <<
    "}"
  end

  def after_edit_method( options )
    content = "function(tr,tr_edit){"
    content << "tr_edit.select('table.nested').each(FT.reset_add_remove_for);" if @enable_nested_records
    content << @after_init_edit if @after_init_edit
    content << "}"
  end
  
end