# Returning Interactions
### Example: User Signup
```ruby
# app/interactions/public/users/create.rb

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
		
		user = User.new(inputs)
	    user.update(inputs.except(:user))
	    user
	end
end

```

**Here is the same User Signup interaction from 07-regular_interactions as a ReturningInteraction.** I'll point out some unique aspects in contrast to regular interactions:

* The returning interaction inherits from a different parent class.
* We specify the return value.
* We added a new input filter: the `:user` ActiveRecord instance that will be created.
* The execute method is now called execute_returning.
* `Halt_if_errors!` Is renamed to `return_if_errors!` on line 15

This interaction is guaranteed to return the :user input argument, no matter if input values are not valid, or if we run into any errors in the `execute_returning!` method. We know we’ll get back the `:user` instance. Any errors that emerged in the interaction, or one of its delegated interactions, will be merged into the user instance so that they are available when we re-render the form.

### Example: ReturningInteraction in a Controller

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
* Because it is a proper ActiveRecord instance, you can pass the return value to the re-rendered form, and then you have access to all the ActiveRecord conveniences like associations, and all instance methods that exist on the model.

You may be wondering when to use regular vs returning interactions. Very generally, returning interactions can be used for Rails form integration, and regular interactions for everything else.

I hope that you can see the value of using interactions.

