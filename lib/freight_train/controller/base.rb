require 'java_script_generator.rb'

class FreightTrain::Controller::Base < ActionController::Base
  include FreightTrain::Controller::Helpers::ActionBuilder
  
  # include all FreightTrain helpers
  dir = "vendor/plugins/freight_train/lib/freight_train/helpers"
  extract = /^#{Regexp.quote(dir)}\/?(.*).rb$/
  Dir["#{dir}/**/*_helper.rb"].each do |file|
    h = "freight_train/helpers/#{file.sub(extract,'\1')}"
    require h
    add_template_helper(h.camelize.constantize)
  end
  
  # include all FreightTrain helpers
  #dir = "vendor/plugins/freight_train/lib/freight_train/controller/helpers"
  #extract = /^#{Regexp.quote(dir)}\/?(.*).rb$/
  #Dir["#{dir}/**/*_helper.rb"].each do |file|
  #  h = "freight_train/controller/helpers/#{file.sub(extract,'\1')}"
  #  #require h
  #  include h.camelize.constantize
  #  #require h
  #  #add_template_helper(h.camelize.constantize)
  #end

  class << self
    def default_form_builder; ActionView::Base.default_form_builder; end
    def default_form_builder=(value); ActionView::Base.default_form_builder = value; end
    def default_row_builder; FreightTrain::Builders::RowBuilder.default_row_builder; end
    def default_row_builder=(value); FreightTrain::Builders::RowBuilder.default_row_builder = value; end  
    def default_inline_editor_builder; FreightTrain::Builders::InlineFormBuilder.default_inline_editor_builder; end
    def default_inline_editor_builder=(value); FreightTrain::Builders::InlineFormBuilder.default_inline_editor_builder = value; end
  end
  
  ActionView::Base.default_form_builder = FreightTrain::Builders::FormBuilder

end