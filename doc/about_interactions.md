# About Interactions

## When to use interactions

When to use an interaction:

* Integration with Rails CRUD forms:
  * FormObject preparation.
  * FormParams sanitization/transformation
  * special validations
  * CRUD persistence operations
  * post-persistence actions like sending an email, or triggering another interaction
* Decoupling behavior from ActiveRecord classes:
  * Replace **ALL** ActiveRecord `:after_...` callbacks with interactions. This refers to all after callbacks, not just save.
  * Replace **MOST** ActiveRecord `:before_...` callbacks with interactions. This refers to all `:before_…` callbacks, not just save. An exception that can remain as a callback could be a `:before_validation` callback to sanitize an email address (strip surrounding whitespace, lower case), however, if there is already an interaction to create/update a user, you may as well do it in the interaction.
  * Replace Model instance and class methods that implement complex behaviours with interactions. Note that you can still use the Model methods as interface, however, the implementation should live in an interaction.
* Implement complex domain behaviours by composing sub tasks into higher level processes.
* Wrap a 3rd party service so that we can swap it out in a single place if needed.

## ReturningInteractions

ReturningInteractions are a special kind of interaction, optimized for usage with Rails forms.

### Motivation

When processing a Rails form submission, e.g., via :create or :update, if the inputs are not valid (and the interaction’s input validation fails), we still need a form object that we can use to re-render the form. When an ActiveInteraction’s input validation fails, we don’t get that. We just get the errors and the interaction itself. And the interaction may not be a suitable stand-in for the model object if it does not implement all the methods found on the model object (e.g., associations or decorators).

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
* They inherit from ReturningInteraction.
* They have an additional returning macro to specify which one of the inputs is guaranteed to be returned.
* The `#execute` method is replaced with `#execute_returning`.

### Additional notes

* They require the returned input argument to implement the ActiveModel::Errors interface so that any errors can be merged.
* They behave very similar to the Ruby `#tap` method.
* Instead of an ActiveRecord instance, you can also pass the record’s id to a ReturningInteraction. This is possible thanks to ActiveInteraction’s record input filter type.
* Convention for input arguments: Don’t nest object attrs in a hash since ActiveInteraction doesn’t have good input filter error reporting on nested values. It’s better to have all attrs as flat list, merged with the returned record. (NOTE: This may be addressed with ActiveInteraction v5)
