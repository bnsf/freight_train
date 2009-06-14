module FreightTrain::Controller::Helpers::Core

  def show_errors_for( record, options={} )
	render :update do |page|
	  page.show_error format_errors( record )
	  page.alert options[:alert] if options.key?(:alert)
	end
  end 

  def show_exception_for( record, options={} )
	render :update do |page|
	  page.show_error format_exception_for(record, options.merge(:action => @current_action))
	  page.alert options[:alert] if options.key?(:alert)
	end
  end

  def refresh_on_create( refresh, record, options={} )
	options[:originating_controller] = params[:originating_controller]

	render :update do |page|
	  page.hide "error"

	  case refresh
	  when :single
		page.add_record record, options
	  else
		options[:find] = get_finder(options[:find] || {})
		page.refresh_records record.class, options
	  end

	  page.call "FT.highlight", idof(record)
	  page.call "FT.on_created"
	end
  end

  def refresh_on_update( refresh, record, options={} )
	options[:originating_controller] = params[:originating_controller]

	render :update do |page|
	  page.hide "error"
	  page.call "InlineEditor.close"

	  case refresh
	  when :single
		# this is kind of a clunky way of solving this problem; but I want row_for to know whether
		# it is creating a row or updating a row (whether it should write the TR tags or not).
		@update_row = true
		page.refresh_record record, options
	  else
		options[:find] = get_finder(options[:find] || {})
		page.refresh_records record.class, options
	  end

	  page.call "FT.highlight", idof(record)
	end
  end

  def remove_deleted( record )
	render :update do |page|
	  page.call "FT.delete_record", idof(record)
	end
  end
  
private

  def get_finder( finder_hash )
	finder_hash.is_a?(Symbol) ? send(finder_hash) : finder_hash
  end
  
end