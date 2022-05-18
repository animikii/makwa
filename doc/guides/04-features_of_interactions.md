# Features of Interactions

### Input validation and coercion
All input arguments are validated and coerced before the interaction is invoked. Depending on the use case we can use the following validations:
- ActiveInteraction input filters - Check for the presence of input argument keys, and their types, and can set default values for optional input arguments.
- ActiveModel validations in the Interaction. - Use the full power of ActiveModel::Validation to check for specific values or higher-level business rules that are specific to the interaction.
- ActiveModel validations in the ActiveRecord instance passed to a ReturningInteraction - For shared validations that apply to all related interactions.
- Dry-validation-based contracts for advanced validations of deeply nested data structures.

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
* Composed interactions act like the #run! bang method with exception handling built-in.

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

