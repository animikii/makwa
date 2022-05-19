# Example: RunReturningInteraction
# This is an example of a widgets controller

# app/controllers/i_app_data/i_widgets_controller/managed_by_app.rb
def create
  authorize([:i_app_data, IWidget])
  ar_attrs = params
               .fetch(:i_widget, {})
               .to_unsafe_hash
               .transform_values(&:presence) # convert empty strings to nil for interaction input filters
  @i_widget = ::IAppData::IWidgets::Create.run_returning!(
    { i_widget: IWidget.new(ar_attrs) }.merge(ar_attrs),
    )
  if @i_widget.errors_any?
    @ndb_table = DataApp::NwTable.find(:i_widget)
    @ar_instance = @i_widget
    render template: ndb_new_template
  else
    redirect_to(i_app_data_i_widgets_path)
  end
end

# The invoked interaction:
# app/interactions/i_app_data/i_widgets/create.rb
module IAppData
  module IWidgets
    # Creates a new IWidget
    class Create < ReturningInteraction

      returning :i_widget

      record :i_widget, class: IWidget
      boolean :i_boolean_attr
      string :i_color_attr, default: nil
      date :i_date_attr
      string :i_email_attr
      integer :i_integer_attr, default: nil
      float :i_percentage_attr, default: nil
      string :i_permission_id, default: nil
      string :i_text_html_attr, default: nil
      string :i_text_markdown_attr, default: nil
      string :i_text_plain_attr, default: nil
      string :i_user_id

      def execute_returning
        unless i_widget.update(inputs.except(:i_widget))
          errors.merge!(i_widget.errors)
        end
      end

    end
  end
end
