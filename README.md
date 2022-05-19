# Makwa

Interactions for Ruby on Rails.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'makwa'
```

And then execute:

```shell
$ bundle install
```

Or install it yourself as:

```shell
$ gem install makwa
```

Makwa extends the Active Interactions gem, and will install it automatically.

## Usage

### Here is an example of an Interaction and a Controller which invoked the Interaction

```ruby

class Create < ApplicationInteraction

  # Input filters
  string :email
  string :name
  string :password

  # ActiveModel validations
  validates :email, presence: true
  validates :name, presence: true
  validates :password, presence: true, length: { minimum: 6 }

  # @return [User]
  def execute
    user = User.new(inputs)
    errors.merge!(user.errors) unless user.update(inputs.except(:user))
    halt_if_errors!
    user.update(inputs.except(:user))
    user
  end

end
```

The interaction file is located at app/interactions/public/users/create.rb. Our documentation contains good tips for
naming conventions.

We first specify the input filters. They will check for the presence and correct type of each input argument. They can
do type casting if needed, and provide default values. Here we expect three string arguments for email, name, and
password.

Next you see input data validations using standard ActiveModel validations. These will be applied to the input
arguments. Execution will stop if there are any validation errors. Finally we have the execute method where we implement
the behavior. This method is called only if all inputs are present and valid. In the execute method we have access to
the errors collection.

We halt execution if there are any errors. Only if everything has worked as expected so far, do we cause the additional
side effects of sending emails, etc.

Only then do we return the newly created user.

```ruby

module Public
  class UsersController < BaseController

    def create
      outcome = Public::Users::Create.run(oarams[:user].to_unsafe_hash)
      if outcome.errors_empty?
        redirect_to dashboard_path, notice: "Welcome to our app!"
      else
        @user = outcome
        render(:new)
      end
    end

  end
end
```

This is how we invoke the Interaction from the controller:

We call it with the user params. Notice that we’re not using StrongParameters. The interaction knows which arguments are
allowed and will validate them in a much more powerful way than StrongParameters can do.

We assign the return value to `outcome` and check if it has no errors. If there are errors we re-render the signup form
and use the interaction itself as the form object. The interaction has public getters for all input arguments, and it
implements the ActiveModel errors interface, so form errors will be displayed as expected.

We can reuse the interaction code by invoking the same interaction from the Hootsuite API users controller.

Further documentation can be found in [docs](doc/guides/01-why_interactions_tldr.md)

More examples can be found in [doc/examples](dov/examples)

## Development

Development instructions found in [gem_development](gem_development/how_to_release_new_version.md)

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/animikii/makwa.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
