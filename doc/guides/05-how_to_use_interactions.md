# How to use Interactions

For basic usage of ActiveInteractions, see the ActiveInteraction gem documentation
here: https://github.com/AaronLasseigne/active_interaction#basic-usage

### Installing Interactions into your App

To start using interactions in your app, add this line to your Gemfile:

```ruby
gem "makwa"
```

Then, create the "interactions" folder in your "app" directory, and create your interaction files:

```ruby
# app/interactions/application_interaction.rb
class ApplicationInteraction < Makwa::Interaction
end

# app/interactions/application_returning_interaction.rb
class ApplicationReturningInteraction < Makwa::ReturningInteractions
end
```

