class FreightTrain::Builders::CheckListBuilder

  def initialize(method, array, value, template)
    @method, @array, @value, @template = method, array, value, template
  end

  def check_box(*args)
    content = "<input type=\"checkbox\" name=\"#{@method}[]\" value=\"#{@value}\""
    content << " checked=\"checked\"" if @array.member? @value
    content << " />"
  end

end