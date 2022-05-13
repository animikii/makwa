# Returning Interactions

## Example: User Signup

```ruby
# app/interactions/public/users/create.rb
module Public
  module Users
    class Create < ReturningInteraction
      
      returning :user
      
      record :user, class: User, default: => { User.new }

      # Input filters
      string :email
      string :name
      string :password

      # ActiveModel validations
      def execute_returning
        errors.merge!(user.errors) unless user.update(inputs.except(:user))
        return_if_errors!
        
        UserMailer.with(user: user).welcome_email.deliver_later
        track_analytics_event(:signup, user)
        MailchimpApi.delay.add_to_list(
          ENV['MAILCHIMP_CUSTOMER_LIST_ID'],
          user.email,
          user.created_at.to_s(:mailchimp_date)
        )
      end
    end
  end
end
```

**Here is the User Signup interaction from reference page 06 as a ReturningInteraction.** I'll point out some unique aspects in contrast to regular interactions:

* The returning interaction inherits from a different parent class.
* We specify the return value on line 6.
* We added a new input filter: the `:user` ActiveRecord instance that will be created.
* The execute method is now called execute_returning.
* `Halt_if_errors!` Is renamed to `return_if_errors!` on line 15
* The side effects at the end are identical to regular interactions.

This interaction is guaranteed to return the :user input argument, no matter if input values are not valid, or if we run into any errors in the `execute_returning!` method. We know we’ll get back the `:user` instance. Any errors that emerged in the interaction, or one of its delegated interactions, will be merged into the user instance so that they are available when we re-render the form.

## Example: ReturningInteraction in a Controller

```ruby
module Public
  class UserController < BasicController
    
    def create
      @user = ::Public::Users::Create.run_returning!(
        { user: User.new }.merge(params[:user].to_unsafe_hash),
      )
      if @user.errors_any?
        render(:new)
      else
        redirect_to dashboard_path, notice: "Welcome to our app"
      end
    end

  end 
end
```

**Using a ReturningInteractions in a controller is very similar to invoking a regular interaction.**
* Instead of :run we invoke it with :run_returning!, and we pass a user argument that is initialized to a new User record.
* Notice how we don’t have to set up the form object in case of errors. The interaction is guaranteed to return the User instance.
* Because it is a proper ActiveRecord instance, we can pass the return value to the re-rendered form, and we have access to all the ActiveRecord conveniences like associations, and all instance methods that exist on the model.

You may be wondering when to use regular vs returning interactions.
* I've been using half regular and half returning interactions in Niiwin so far.
* I use returning interactions for Rails form integration. And regular interactions for everything else.

I hope that you can see the value of using interactions.

