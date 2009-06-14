module FreightTrain::Helpers::FormHelper

  def auto_complete_text_field_tag(method, options={})
    url = options.delete(:url)
    #url[:action] = "autocomplete_#{method}"
 
    content = @template.text_field_tag(method, options[:value], options)
    content << "<div class=\"auto_complete\" id=\"#{method}_auto_complete\"></div>"
    content << @template.auto_complete_field(method, {:url => url})
  end

end