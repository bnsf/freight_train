class FreightTrain::Builders::NestedFormBuilderWrapper

  def initialize(object_name, object, template, options, proc)
    #template.concat "<!-- I'm in! -->"
    @builder = FreightTrain::Controller::Base.default_form_builder.new(object_name, object, template, options, proc)
  end
  
  def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
    html_options[:class] = "field"
    html_options[:id] = method
    @builder.collection_select(method, collection, value_method, text_method, options, html_options)
  end
  
  def text_field(method, *args)
    options = args.extract_options!
    options[:class] = "field"
    options[:id] = method
    @builder.text_field(method, options)
  end
  
  def check_box(method, *args)
    options = args.extract_options!
    options[:class] = "field"
    options[:id] = method
    @builder.check_box(method, options)
  end
  
  def method_missing(sym, *args, &block)
    @builder.send sym, *args, &block
  end

end