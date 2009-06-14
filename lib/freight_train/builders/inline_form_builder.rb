class FreightTrain::Builders::InlineFormBuilder < ActionView::Helpers::FormBuilder
  include ActionView::Helpers::TagHelper

  @@default_inline_editor_builder = FreightTrain::Builders::InlineFormBuilder
  def self.default_inline_editor_builder; @@default_inline_editor_builder; end
  def self.default_inline_editor_builder=(val); @@default_inline_editor_builder=val; end
  
  
  # ===================================================================================================
  # ABOUT INLINE_FORM_BUILDER
  # ===================================================================================================
  #
  # This is used to make an entire Ruby block into a single-quoted JavaScript string that,
  # when inserted into a document, creates an inline editor.
  #
  # The inline editor is created by scraping values from known places in the read-only row
  # which the user intends to edit.
  #
  # These methods are responsible for:
  #
  # (1) finding the right values in the document
  #     * These methods can rely on the JavaScript variable 'tr' which contains a
  #       Prototype-extended reference to the read-only row that user intends to edit.
  #     * Methods can concatenate the code "return null;" to prevent the editor from
  #       being shown if a critical value cannot be found.
  #
  # (2) assembling the html that describes the inline editor
  #     * The methods of this custom FormBuilder are intended to be concatenated to a
  #       single-quoted JavaScript string that returns that HTML of the inline editor.
  #     * Any method can append pure JavaScript code by concatenating "';" to close
  #       the string. Concatenate "html += '" to reopen the string.
  #     * Methods always need to leave the string open when they exit so that HTML
  #       defined in the ERB file outside of the FormBuilder will be respected. As a
  #       corollary, methods can always assume that they are concatenating to an open string.
  #
  # ===================================================================================================
    

  def initialize(object_name, object, template, options, proc)
    super
    @after_init_edit = @template.instance_variable_get("@after_init_edit")
  end

  def check_box(method, options={})
    attr_name = "#{@object_name}[#{method}]"
    code(
      "e = tr.down('*[attr=\"#{attr_name}\"]');if(!e){alert('#{attr_name} not found');return null;}" <<
      "var checked = (e.readAttribute('value')=='true');"
    ) <<
      "<input name=\"#{attr_name}\" type=\"hidden\" value=\"0\"/>" <<
      "<input name=\"#{attr_name}\" type=\"checkbox\"'+(checked ? 'checked=\"checked\"' : '')+' value=\"1\" />"
  end

  def check_list_for(method, values, &block)
    attr_name = "#{@object_name}[#{method}]"
    @after_init_edit << "FT.check_selected_values(tr,tr_edit,'#{attr_name}');"
    for value in values
      yield FreightTrain::Builders::CheckListBuilder.new(attr_name, [], value, @template)
    end
  end

  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    attr_name = "#{@object_name}[#{method}]"
    @after_init_edit << "FT.copy_selected_value(tr,tr_edit,'#{attr_name}','#{method}');"

    html_options[:id] = method unless html_options[:id]
    html_options[:name] = attr_name
    
    o = "["
    collection.each do |i|
      o << "," if (o.length > 1)
      # prevent options that contain apostrophes from screwing things up
      o << "['#{i.send(value_method).to_s.gsub( Regexp.new("'"), "\\\\'")}','#{i.send(text_method).to_s.gsub( Regexp.new("'"), "\\\\'")}']"
    end
    o << "]"
    
    "#{tag("select", html_options, true)}'+FT.create_options(#{o})+'</select>"
  end
  
  def fields_for( method, *args, &block )
    options = args.extract_options!
    yield @@default_inline_editor_builder.new( "#{@object_name}[#{method}]", nil, @template, options, block )
  end

  def hidden_field( method )
    options = { :type => "hidden" }
        
    code(
      "e=tr.select('*[attr=\"#{@object_name}[#{method}]\"]');" <<
      "if(e.length==1){"
    ) <<
      
      @template.tag( "input", {
        :type=>"hidden",
        :value=>"'+e[0].readAttribute('value')+'",
        :name=>"#{@object_name}[#{method}]"} ) <<
      
    code(
      "}else{" <<
        "for(var i=0; i<e.length; i++){"
    ) <<
    
      @template.tag( "input", {
        :type=>"hidden",        
        :value=>"'+e[i].readAttribute('value')+'",
        :name=>"#{@object_name}[#{method}][]"} ) <<
    
    code(
        "}" <<
      "}"
    )
  end

  def nested_editor_for( method, *args, &block )
    raise ArgumentError, "Missing block" unless block_given?
    options = args.extract_options!
    
    attr_name = "#{@object_name}[#{method}]"
    name = "#{@object_name}[#{method}_attributes]"
    @template.instance_variable_set "@enable_nested_records", true

    # for some reason, things break if I make "#{@object_name}[#{object_name.to_s}_attributes]" the 'id' of the table
    @template.concat "<table class=\"nested editor\" name=\"#{name}\">"

    # This FormBuilder expects 'tr' to refer to a TR that represents and object and contains
    # TDs representing the object's attributes. For nested objects, the TR is a child of the
    # root TR. Create a closure in which the variable 'tr' refers to the nested object while
    # preserving the reference to the root TR.
    @template.concat code(
      "(function(root_tr){" <<
      "var nested_rows=root_tr.select('table[attr=\"#{attr_name}\"] tr');" <<
      #"alert('#{attr_name}: '+nested_rows.length);" <<
      "for(var i=0; i<nested_rows.length; i++){" << 
        "var tr=nested_rows[i];"
    )
    @after_init_edit << "FT.for_each_row(tr,tr_edit,'table[attr=\"#{attr_name}\"] tr','table[name=\"#{name}\"] tr',function(tr,tr_edit){"

    fields_for method, nil, *args do |f|
      @template.concat "<tr id=\"#{method.to_s.singularize}_'+i+'\">"
      block.call(f)
      @template.concat "<td><a class=\"delete-link\" href=\"#\" onclick=\"FT.delete_nested_object(this);return false;\"><div class=\"delete-nested\"></div></a></td>"
      @template.concat "<td><a class=\"add-link\" href=\"#\" onclick=\"FT.add_nested_object(this);return false;\"><div class=\"add-nested\"></div></a></td>"
      @template.concat "</tr>"
    end
    @after_init_edit << "});"
    @template.concat code( "}})(tr);" )
    
    @template.concat "</table>"
  end

  def select(method, choices, options = {}, html_options = {})
    attr_name = "#{@object_name}[#{method}]"
    @after_init_edit <<
      "var e = tr.down('*[attr=\"#{attr_name}\"]');" <<
      "var sel = tr_edit.down('select[name=\"#{attr_name}\"]');" <<
      "if(sel && e) FT.select_value(sel,e.readAttribute('value'));" <<
      "else{if(!e) alert('#{attr_name} not found');if(!sel) alert('#{method} not found');}"
    super
  end

  def text(method, options={})
    attr_name = "#{@object_name}[#{method}]"
    code(
      "e=tr.down('*[attr=\"#{attr_name}\"]');" <<
      "if(!e){alert('#{attr_name} not found'); return null;}" <<
      "html += e.innerHTML;"
    )
  end

  def text_field(method, options={})
    attr_name = "#{@object_name}[#{method}]"
    options[:id] = method unless options[:id]
    code(
      "e=tr.down('*[attr=\"#{attr_name}\"]');" <<
      "if(!e){alert('#{attr_name} not found'); return null;}" <<
      #"alert(e.readAttribute('value'));" <<      
      "var #{method}=e.readAttribute('value')||e.innerHTML;"
    ) << 
    @template.tag( "input", options.merge(
      :type => "text",
      :name => "#{attr_name}",
      :value => "'+#{method}+'"))
  end

  
private

  
  def code(string)
    "';" << string << "html+='"
  end
  
end