# Makwa Interaction Usage Examples

## Install the Gem

Add the `makwa` gem to your Gemfile.

## Specify your Application interactions

All specific interactions will inherit from your app-wide interactions:

```ruby
# app/interactions/application_interaction.rb
class ApplicationInteraction < Makwa::Interaction
  def debug(txt)
    # Uncomment the next line for detailed debug output
    # puts indent + txt
  end
end
```

```ruby
# app/interactions/application_interaction.rb
class ApplicationReturningInteraction < Makwa::ReturningInteraction
  def debug(txt)
    # Uncomment the next line for detailed debug output
    # puts indent + txt
  end
end
```

## Implement a regular interaction to wrap a 3rd party service

This example interaction wraps an email sending service:

```ruby
# app/interactions/infrastructure/send_email.rb
module Infrastructure
  class SendEmail < ApplicationInteraction
    string :recipient_email
    string :subject
    string :body

    validates :recipient_email, presence: true, format: {with: /.+@.+/}
    validates :subject, presence: true

    def execute
      ThirdPartyEmailService.send(
        to: recipient_email,
        subject: subject,
        body: body
      )
    end
  end
end
```

## Implement a ReturningInteraction to create a user

```ruby
# app/users/create.rb
module Users
  class Create < ApplicationReturningInteraction
    returning :user

    string :first_name
    string :last_name
    string :email
    record :user

    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true, format: {with: /.+@.+/}

    def execute_returning
      user.update(inputs.except(:user))
      return_if_errors!

      compose(
        Infrastructure::SendEmail, # See the example above for details
        recipient_email: user.email,
        subject: "Welcome to Makwa",
        body: "Lorem ipsum..."
      )
    end
  end
end
```

Use this interaction from the controller:

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    # Differences: Pass in the `:user` input and call `#run_returning!` instead of `#run`.
    @user = Users::Create.run_returning!(
      {user: User.new}.merge(params.fetch(:user, {}))
    )

    if @user.errors_empty?
      redirect_to(@user)
    else
      render(:edit)
    end
  end
end
```

## Implement a ReturningInteraction to update a user

```ruby
# app/users/update.rb
module Users
  class Update < ApplicationReturningInteraction
    returning :user

    string :first_name
    string :last_name
    string :email
    record :user

    validates :first_name, presence: true
    validates :last_name, presence: true
    validates :email, presence: true, format: {with: /.+@.+/}

    def execute_returning
      user.update(inputs.except(:user))
    end
  end
end
```

Use this interaction from the controller:

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :load_user

  def edit
  end

  def update
    @user = Users::Create.run_returning!(
      {user: @user}.merge(params.fetch(:user, {}))
    )

    if @user.errors_empty?
      redirect_to(@user)
    else
      render(:edit)
    end
  end
end
```

## Usage conventions

Interactions follow these conventions:

* **Code location**: Interactions are stored in app/interactions.
* **Naming**: Interaction names always start with a verb, optionally followed by an Object noun. The Interaction’s parent namespaces provide additional context. When referring to ActiveRecord models in an interaction’s parent namespace, use plural form. This is to avoid naming conflicts with ActiveRecord models. Examples:
  * `users/create.rb`
  * `facilitator/groups/close.rb`
  * `nw_app_structure/nw_patch_items/nw_tables/change/prepare_form_object.rb`
* **Inheritance**: Interactions inherit from ApplicationInteraction, ApplicationReturningInteraction, or one of their descendants.
* **Invocation**: You can invoke an Interaction in one of the following ways:
  * `.run` - always returns the Interaction outcome. You can then query the outcome with `#errors_empy?`, `#errors_any?`, `#result` and `#errors`. This is the primary way of invoking Interactions. Example: `outcome = NwAppStructure::NwPatches::Apply.run(id: "1234abcd")`
  * `.run!` - the bang version returns the Interaction’s return value if successful, and raises an exception if not successful. This can be used as a convenience method where we want to assure that the interaction executes successfully, and where we want easy access to the return value.
  * **ReturningInteractions** can only be invoked with `.run_returning!`.
* **Input param safety**: Interactions validate, restrict, and coerce their input args. That means you don't need strong params. You can use raw controller params via `user_params: params.to_unsafe_h[:user]`.
* **Error handling**:
  * Rely on ActiveModel validations to add errors to the interaction.
  * Use `errors.add` and `errors.merge!` to manually add errors to an interaction.
  * When composing interactions, errors in nested interactions bubble to the top.
  * Errors can be used for flow control, e.g., via `#return_if_errors!`.
* **Outcome**: Regular interactions that are invoked with `.run` return an outcome:
  * Outcome can be tested for presence/absence of any errors. Please use `#errors_empty?` and `#errors_any?` instead of `#valid?`. See caveat below related to `#valid?` for details.
  * Outcome has a `#result` (return value of the #execute method).
  * Outcome exposes any errors via an `ActiveModel::Errors` compatible API.
* **Input arguments**:
  * Input arguments to an interaction are always wrapped in a Hash. The hash keys correspond to the interaction’s input filters.
  * As a general guideline, interactions receive the same types of arguments as the corresponding controller action would expect as `params`: Only basic Ruby data types like Hashes, Arrays, Strings, Numbers, Dates, Times, etc. This convention provides the following benefits:
    * Provides the simplest API possible.
    * Makes it easy to invoke an Interaction from a controller action: Just forward the params as is.
    * Makes it easy to invoke an interaction from the console. You can type all input args as literals.
    * Makes it easy to pass test data into an interaction.
    * Makes it easy to serialize the invocation of an interaction, e.g., for a Sidekiq background job.
    * We do not pass in ActiveRecord instances, but their ids instead. We rely on ActiveRecord caching to prevent multiple DB reads when passing the same record id into nested interactions. Exceptions:
      * You can pass a descendent of ActiveModel, e.g., an ActiveRecord instance as the returned input to a ReturningInteraction. Use the record input filter type. It accepts both the ActiveRecord instance, as well as its id attribute. That way, you can still pass in basic Ruby types, e.g., in the console when invoking the interaction.
      * In some use cases with nested interactions, we may choose to pass in an ActiveRecord instance to work around persistence concerns.
  * When an interaction is concerned with an ActiveRecord instance, we pass the record’s id under the :id hash key (unless it’s a ReturningInteraction).

## Caveat: Don’t use #valid?

We need to address the issue where the supposedly non-destructive ActiveModel method `#valid?` is actually destructive. This affects both ActiveModel::Validations as well as ActiveInteraction. The `#valid?` method actually clears out any existing errors and re-runs ActiveModel validations. This causes any errors added outside of an ActiveModel::Validation to disappear, resulting in `#valid?` returning true when it shouldn’t.

Don't use `#valid?`, use `#errors_empty?` instead.

Don't use `#invalid?`, use `#errors_any?` instead.

Rails source code at activemodel/lib/active_model/validations.rb, line 334:

```ruby
def valid?(context = nil)
  current_context, self.validation_context = validation_context, context
  errors.clear
  run_validations!
ensure
  self.validation_context = current_context
end
```

The official Rails way to circumvent the clearing of errors is to use errors.any? or errors.empty?

We wrap this implementation detail (calling errors.any?) in a method that clearly communicates intent, prevents well intentioned devs from changing `#errors.empty?` to `#valid?`, and helps us audit code to make sure that we're not using the default `#valid?` method in connection with Interactions (Both on the interaction itself, and on any ActiveRecord instances it touches).
