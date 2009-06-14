module FreightTrain::Controller::Helpers::ActionBuilder
 #include FreightTrain::Helpers::FormattingHelper
  include FreightTrain::Controller::Helpers::Core

  module ClassMethods

    def mapped_actions_for(resource_type, mod, *args)
      options = args.extract_options!      
      actions = get_actions(resource_type, options)
     #finder_hash = options[:find] || {}
     #new_hash = options[:new] || {}
      formats = options[:formats] || [:html, :xml]

      default_refresh = :single
      refresh = options[:refresh]
      case refresh
      when Symbol
        refresh_on_update = refresh
        refresh_on_create = refresh
      when Hash
        refresh_on_update = refresh[:update] || default_refresh
        refresh_on_create = refresh[:create] || default_refresh
      else
        refresh_on_update = default_refresh
        refresh_on_create = default_refresh
      end

      module_name = mod.name
      collection_name = module_name.tableize
      instance_name = collection_name.singularize

      if actions.member? :index
        define_method "index" do
          respond_to do |format|
            collection = mod.find(:all, get_finder(options[:find]))
            instance_variable_set("@#{collection_name}", collection)
            instance_variable_set("@#{instance_name}", mod.new(options[:new]||{})) if (resource_type == :simple_record)

            format.html                                                       #if formats.member? :html
            format.xml  { render :xml => collection }                         #if formats.member? :xml
            format.yml  {}                                                    if formats.member? :yml
          end
        end
      end

      if actions.member? :show
        define_method "show" do
          respond_to do |format|
            record = mod.find(params[:id])
            instance_variable_set("@#{instance_name}", record)

            format.html                                                       #if formats.member? :html
            format.xml  { render :xml => record }                             #if formats.member? :xml
            format.yml  {}                                                    if formats.member? :yml
          end
        end
      end
      
      if actions.member? :new
        define_method "new" do
          respond_to do |format|
            record = mod.new(options[:new])
            instance_variable_set("@#{instance_name}", record)

            format.html                                                       #if formats.member? :html
            format.xml  { render :xml => record }                             #if formats.member? :xml
            format.yml  {}                                                    if formats.member? :yml
          end
        end
      end
      
      if actions.member? :create
        define_method "create" do
          respond_to do |format|
            begin
            record = mod.new(params[instance_name])
            instance_variable_set("@#{instance_name}",record)

            #render :update do |page| page.alert "params:\r\n" + format_params; end; return;

            if record.save
              if (resource_type == :simple_record)
                format.html { refresh_on_create(refresh_on_create, record, options) }
              else
                format.html { redirect_to record }
              end
              format.xml  { render :xml => record, :status => :created, :location => record }
            else
              format.html { show_errors_for record }
              format.xml  { render :xml => record.errors, :status => :unprocessable_entity }
            end
            #rescue Exception
            #  format.html { show_exception_for record }
              #format.xml {}
            end
          end
        end   
      end

      if actions.member? :edit
        define_method "edit" do
          record = mod.find(params[:id])
          instance_variable_set("@#{instance_name}", record)
        end
      end

      if actions.member? :update
        define_method "update" do
          respond_to do |format|
            begin
            record = mod.find(params[:id])
            instance_variable_set("@#{instance_name}",record)

            #render :update do |page| page.alert "params:\r\n" + format_params; end; return;

            if record.update_attributes(params[instance_name])
              if (resource_type == :simple_record)
                format.html { refresh_on_update(refresh_on_update, record, options) }
              else
                format.html { redirect_to record }
              end
              format.xml  { head :ok  }
            else
              format.html { show_errors_for record }
              format.xml  { render :xml => record.errors, :status => :unprocessable_entity }
            end
            #rescue Exception
            #  format.html { show_exception_for record }
              #format.xml {}
            end
          end
        end
      end

      if actions.member? :update_color
        define_method "update_color" do
          respond_to do |format|
            begin
            record = mod.find(params[:id])
            instance_variable_set("@#{instance_name}",record)

            if record.update_attributes(params[instance_name])
              format.html { refresh_updated_color_for record }
              format.xml  { head :ok  }
            else
              format.html { show_errors_for record }
              format.xml  { render :xml => record.errors, :status => :unprocessable_entity }
            end
            rescue Exception
              format.html { show_exception_for record }
              #format.xml {}
            end
          end
        end
      end

      if actions.member? :destroy
        define_method "destroy" do
          respond_to do |format|
            record = mod.find(params[:id])
            instance_variable_set("@#{instance_name}",record)

            if record.destroy
              format.html { remove_deleted record }
              format.xml  { head :ok  }
            else
              #format.html { show_errors_for record }
              #format.xml  { render :xml => record.errors, :status => :unprocessable_entity }
            end
          end
        end
      end
    end

    def get_actions( resource_type, options={} ) 
      only = options[:only]
      except = options[:except]
      extra = options[:include]

      if only
        actions = only
      elsif except
        actions = get_standard_actions(resource_type) - except
      else
        actions = get_standard_actions(resource_type)
      end
      actions = (actions + extra) if extra
      return actions
    end

    def get_standard_actions( resource_type )
      case resource_type
      when :simple_record
        [:index, :show, :create, :update, :destroy]
      else
        [:index, :show, :new, :create, :edit, :update, :destroy]
      end
    end

  end

private

  def self.included(other_module)
    other_module.extend ClassMethods
  end

  def get_finder( finder_hash )
    finder_hash.is_a?(Symbol) ? send(finder_hash) : finder_hash
  end

end