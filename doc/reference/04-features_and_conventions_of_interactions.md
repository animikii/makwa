# Features of Interactions

### Input validation and coercion
All input arguments are validated and coerced before the interaction is invoked. Depending on the use case we can use the following validations:

- ActiveInteraction input filters - Check for presence of input argument keys, their types, and can set default values for optional input arguments.

- ActiveModel validations in the Interaction. - Use the full power of ActiveModel::Validation to check for specific values, or higher level business rules that are specific to the interaction.

- ActiveModel validations in the ActiveRecord instance passed to a ReturningInteraction - For shared validations that apply to all related interactions.

- Dry-validation based contracts for advanced validations of deeply nested data structures.

The validation solutions listed above offer the following features:

* Type checking.

* Ability to implement complex validation rules.

* Ability to look at other input args when validating an arg.

* Type coercion, e.g., for Rails request params that need to be cast from String to Integer.

* Runtime validation (since we don’t know what arguments are passed to an Interaction at compile time).

* Default values can be assigned when using ActiveInteraction input filters.

Below are some options for input argument validation:

* ActiveModel Validations: https://api.rubyonrails.org/classes/ActiveModel/Validations.html

* ActiveInteraction filters: GitHub - AaronLasseigne/active_interaction: Manage application specific business logic.

* dry-validation contracts: https://dry-rb.org/gems/dry-validation/

### Composability
Input validations can be composed to prevent duplication and allow re-use. Dry validation offers this temporary workaround for composing rules: Composable contracts · [Composable contracts · Issue #593 · dry-rb/dry-validation](https://github.com/dry-rb/dry-validation/issues/593#issuecomment-631597226)

* Errors raised in composed interactions are merged into the parent interaction.

* Execution in parent interaction stops when a composed interaction fails.

* Composed interactions act like the #run! bang method with exception handling built in.

Code example:

```ruby
def execute
r1 = compose(Nested::Service1, arg1: 123, arg2: "a string")
r2 = compose(Nested::Service2, arg1: r1)
end
```
Note that ActiveInteraction input filters can also be reused via import_filters OtherInteraction.

### Exception handling and error reporting

* Errors (not Ruby Exceptions!) added in an interaction are accessible to the caller for testing and notification purposes.

* Errors are addable manually inside the interaction via errors.add(:base, text: "something went wrong", key: :something_went_wrong).

* Errors are mergeable from other sources, e.g., ActiveRecord objects or nested interactions via errors.merge!(@user.errors).

* Early exit of the interaction is possible if an unrecoverable error condition is detected. E.g., via return_if_errors! or return.

### Internationalization
Success and error messages are customizable via Rails' default I18n mechanisms.

### Integration with Rails forms
ReturningInteractions, are a specialized subclass of ActiveInteraction, work well with processing params submitted from Rails forms, and with possible re-rendering of the form if there are any errors.

### Dependency injection
Dependencies can be injected into an interaction, mostly for testing. Example: We inject a fake Git library when testing code that makes git commits. Other examples: File, Time, TwitterApi, etc.

### Serializability
Invocation of an interaction, with its input arguments, can be serialized in a simple, robust, and performant way. We accomplish this by limiting input arguments to basic Ruby types: Hashes, Arrays, Strings, Numbers, and Booleans.

### Logging
Interactions print detailed info to the log. Output includes:

* Name of invoked interaction

* caller

* input args

* any errors

Example:

```ruby
Executing interaction Niiwin::NwLoader::InitialLoad (id#70361484811280)
 ↳ inputs: {} (id#70361484811280)
    Executing interaction Niiwin::NwLoader::NwConfigs::Load (id#70361484766000)
     ↳ called from niiwin/nw_loader/initial_load.rb:14:in `initial_load_nw_config' (id#70361484766000)
     ↳ inputs: {} (id#70361484766000)
     ↳ outcome: succeeded (id#70361484766000)
    Executing interaction Niiwin::NwLoader::NwConfigs::Validate (id#70361476717620)
     ↳ called from niiwin/nw_loader/initial_load.rb:15:in `initial_load_nw_config' (id#70361476717620)
     ↳ inputs: {} (id#70361476717620)
     ↳ outcome: succeeded (id#70361476717620)
 ↳ outcome: succeeded (id#70361484811280)
```
You can turn off logging by overriding the ApplicationInteraction#debug method.

# Conventions
Interactions follow these conventions:

* **Code location**: Interactions are stored in app/interactions.

* **Naming**: Interaction names always start with a verb, optionally followed by an Object noun. The Interaction’s parent namespaces provide additional context. When referring to ActiveRecord models in an interaction’s parent namespace, use plural form. This is to avoid naming conflicts with ActiveRecord models. Examples:

  * `users/create.rb`

  * `facilitator/groups/close.rb`

  * `niiwin/nw_app_structure/nw_patch_items/nw_tables/change/prepare_form_object.rb`

* **Inheritance**: Interactions inherit from ApplicationInteraction, ReturningInteraction, or one of their descendants.

* **Invocation**: You can invoke an Interaction in one of the following ways:

* `.run` - always returns the Interaction outcome. You can then query the outcome with  `#errors_empy?`, `#errors_any?`, `#result` and `#errors`. This is the primary way of invoking Interactions. 
Example: outcome = `NwAppStructure::NwPatches::Apply.run(id: “1234abcd”)`

* `.run!` - the bang version returns the Interaction’s return value if successful, and raises an exception if not successful. This can be used as a convenience method where we want to assure that the interaction executes successfully, and where we want easy access to the return value.

* [ReturningInteractions](https://animikii.atlassian.net/wiki/spaces/SD/pages/167149591/interactions#ReturningInteractions) can only be invoked with `.run_returning!`.

* Input param safety: Interactions validate, restrict, and coerce their input args. That means you don't need strong params. You can use raw controller params via
`user_params: params.to_unsafe_h[:user]`.

* **Error handling**:

  * Rely on ActiveModel validations to add errors to the interaction.

  * Use `errors.add` and `errors.merge!` to manually add errors to an interaction.

  * When composing interactions, errors in nested interactions bubble to the top.

  * Errors can be used for flow control, e.g., via `#return_if_errors!`.

* **Outcome**: Regular interactions that are invoked with `.run` return an outcome:

  * Outcome can be tested for presence/absence of any errors. Please use `#errors_empty?` and `#errors_any?` instead of `#valid?`. See caveat below related to `#valid?` for details.

  * Outcome has a `#result` (return value of the `#execute` method).

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

    * You can pass a descendent of ActiveModel, e.g., an ActiveRecord instance as the returned input to a [ReturningInteraction](https://animikii.atlassian.net/wiki/spaces/SD/pages/167149591/interactions#ReturningInteractions). Use the `record` input filter type. It accepts both the ActiveRecord instance, as well as it’s `id` attribute. That way, you can still pass in basic Ruby types, e.g., in the console when invoking the interaction.

    * In some use cases with nested interactions, we may choose to pass in an ActiveRecord instance to work around persistence concerns.

  * When an interaction is concerned with an ActiveRecord instance, we pass the record’s id under the `:id` hash key (unless it’s a ReturningInteraction).

## Caveat: Don't use `#valid?`

We need to address the issue where the supposedly non-destructive ActiveModel method `#valid?` is actually destructive. This affects both `ActiveModel::Validations` as well as `ActiveInteraction`. The `#valid?` method actually clears out any existing errors and re-runs ActiveModel validations. This causes any errors added outside of an `ActiveModel::Validation` to disappear, resulting in `#valid?` returning true when it shouldn’t.


| **Don’t use** | **Use instead** |
| --- | --- |
| #valid? | #errors_empty? |
| #invalid? | #errors_any? |

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
[#valid? clear errors before run_validations! clears previous DB dependent validations · Issue #20623 · rails/rails](https://github.com/rails/rails/issues/20623#issuecomment-113270488) 

We wrap this implementation detail (calling `errors.any?`) in a method that clearly communicates intent, prevents well intentioned devs from changing `#errors.empty?` to `#valid?`, and helps us audit code to make sure that we're not using the default `#valid?` method in connection with Interactions (Both on the interaction itself, and on any ActiveRecord instances it touches).

### Returning Interactions
ReturningInteractions are a special kind of interaction, optimized for usage with Rails forms.

### Motivation

When processing a Rails form submission, e.g., via `:create` or `:update`, if the inputs are not valid (and the interaction’s input validation fails), we still need a form object that we can use to re-render the form. When an ActiveInteraction’s input validation fails, we don’t get that. We just get the errors and the interaction itself. And the interaction may not be a suitable stand-in for the model object.

This is where ReturningInteractions come into play. Instead of returning themselves when errors exist, they will always return the specified input value. And any errors are merged into the returned value. The convention is to use the ActiveRecord instance as returned input value. Then, if errors exist, the returned instance can be used as form object to re-render the form.

### How they are different from regular interactions

ReturningInteractions inherit from ActiveInteraction, however, they are different in the following ways:

* They will always return the specified input, no matter what happens after you invoke them:

  * If input validations fail, and the `#execute_returning` method is never reached.

  * If associated ActiveModel validations fail.

  * If exceptions are rescued.

  * If the `#execute_returning` method returns early.

  * If it follows the happy path, everything goes as expected, independently of what the `#execute_returning` method returns.

* They merge any errors added to the returned input argument before returning it.

* They inherit from `ReturningInteraction`.

* They have an additional `returning` macro to specify which one of the inputs is guaranteed to be returned.

* The `#execute` method is replaced with `#execute_returning`.

### Additional Notes

* They require the returned input argument to implement the ActiveModel::Errors interface so that any errors can be merged.

* They behave very similar to the Ruby #tap method.

* Instead of an ActiveRecord instance, you can also pass the record’s id to a ReturningInteraction. This is possible thanks to ActiveInteraction’s `record` input filter type.

* Convention for input arguments: Don’t nest object attrs in a hash since ActiveInteraction doesn’t have good input filter error reporting on nested values. It’s better to have all attrs as flat list, merged with the returned record.

* See the pull_request’s readme for more details.
