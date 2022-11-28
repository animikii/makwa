# Makwa

Makwa is an extension of the [ActiveInteraction](https://github.com/AaronLasseigne/active_interaction) gem, bringing interactions to Ruby on Rails apps.

> ActiveInteraction manages application-specific business logic. It's an implementation of service objects designed to blend seamlessly into Rails. It also helps you write safer code by validating that your inputs conform to your expectations. If ActiveModel deals with your nouns, then ActiveInteraction handles your verbs.

<p align="right">Readme for ActiveInteraction.</p>

Makwa improves the ergonomics around mutating ActiveRecord instances.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "makwa"
```

And then execute:

```shell
$ bundle install
```

Or install it yourself as:

```shell
$ gem install makwa
```

Makwa extends the ActiveInteraction gem and will install it automatically as a dependency.

Makwa is compatible with Ruby 2.7 or greater and Rails 5 or greater.

## What does Makwa add to ActiveInteraction?

Please read through the [ActiveInteraction Readme](https://github.com/AaronLasseigne/active_interaction) first and then come back here to see what Makwa adds to ActiveInteraction:

### ReturningInteraction

ReturningInteractions are a special kind of interaction, optimized for usage with Rails forms:

The basic approach of ActiveInteraction (AI) when rendering ActiveRecord model forms is to pass an AI instance to the form. That approach works great for simple mutations of ActiveRecord instances. However, for this to work, the AI class has to implement all methods required for rendering your forms. That can get tricky when you need to traverse associations, or call complex decorators on your models. This approach also fails if the interaction's `#execute` method is never run because the input validations fail.

ReturningInteraction (RI) chooses a different approach: It accepts the to-be-mutated ActiveRecord instance as an input argument and is guaranteed to return that instance, no matter if the interaction outcome is successful or not. The RI will merge all errors that occurred during execution to the returned ActiveRecord instance. This allows you to pass the actual ActiveRecord instance to your form, and you don't have to implement all methods required for the form to be rendered.

Let's look at some example code to see the difference:

The ActiveInteraction way

```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    outcome = Users::Create.run(
      params.fetch(:user, {})
    )

    if outcome.valid?
      redirect_to(outcome.result)
    else
      @user = outcome
      render(:new)
    end
  end
end

# app/interactions/users/create.rb
module Users
  class Create < ApplicationInteraction
    string :first_name
    string :last_name
    array :role_ids, default: []

    def execute
      user = User.new(inputs)
      errors.merge!(user.errors) unless user.save
      user
    end

    def to_model
      User.new
    end
  end
end
```

The Makwa way

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
      render(:new)
    end
  end
end

# app/interactions/users/create.rb
module Users
  class Create < ApplicationReturningInteraction
    returning :user # This is different from AI: Specifies which input will be returned.

    string :first_name
    string :last_name
    string :email
    record :user

    def execute_returning # Notice: Method is called `execute_returning`, not `execute`!
      user.update(inputs.except(:user))
      # No need to merge any errors. This will be done automatically by Makwa
      return_if_errors!

      compose(
        Infrastructure::SendEmail,
        recipient_email: user.email,
        subject: "Welcome to Makwa",
        body: "Lorem ipsum..."
      )
      # No need for an explicit return of user, also done by Makwa
      # (via `returning` input filter).
    end

    # No need to implement the `#to_model` method and any other methods required to
    # render your forms.
  end
end
```

### Other improvements

Makwa offers **safe ways to check for errors**. Instead of `#valid?` or `#invalid?` use `#errors_empty?` or `#errors_any?`. Rails' `#valid?` method is a destructive method that will clear all errors and re-run validations. This will eradicate any errors you added in the body of the `#execute` or `#execute_returning` methods.

Makwa offers a simple way to **exit early** from the interaction. Use `#return_if_errors!` at any point in the `#execute` method if errors make it impossible to continue execution of the interaction.

Makwa offers **detailed logging** around interaction invocations (with inputs) and outcomes (with errors):

```
Executing interaction Users::SendWelcomeEmail (id#1234567)
 ↳ called from Users::Create (id#7654321)
 ↳ inputs: {first_name: "Giselher", last_name: "Wulla"} (id#7654321)
 # ... execute interaction
 ↳ outcome: failed (id#7654321)
 ↳ errors: "Email is missing" (id#7654321)
```

To enable debug logging just define this method in your `ApplicationInteraction`:

```ruby
def debug(txt)
  puts indent + txt
end
```

### Further reading

* [Usage](doc/usage_examples.md): More complex examples and conventions.
* [About interactions](doc/about_interactions.md): Motivation, when to use them.
* [Features and design considerations](doc/features_and_design_considerations.md)

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

We have [instructions for releasing a new version](doc/how_to_release_new_version.md).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/animikii/makwa.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
