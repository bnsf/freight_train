class ActionController::Routing::RouteSet::Mapper

  def records(*entities, &block)
    options = entities.extract_options!
    options[:except] = [:edit]
    map_records(entities, options, &block)
  end

  def simple_records(*entities, &block)
    options = entities.extract_options!
    options[:except] = [:new, :edit]
    map_records(entities, options, &block)
  end

private

  def map_records(entities, options, &block)
    (options[:requirements]||={})[:id] = /[0-9]+/
    entities.each { |entity| map_resource(entity, options.dup, &block) }
    #resources(*entities, options, &block)
  end

end 