# Why should interactions be used:

## Example: User Signup

**To Set the Stage,** we will start with a timelapse of changes to a Rails app without interactions.

1. The first step of our UsersController is to include functionality that allows users to sign up to our app.

```ruby

class UsersController < ApplicationController

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to dashboard_path, notice: "Welcome to our app!"
    else
      render(:new)
    end
  end

end
```

2. Now, a new requirement emerges: We want to send a welcome email to all new users. We can use an ActiveRecord callback
   on the User model. `after_create`  will make this happen magically!

```ruby

class User < ApplicationRecord

  after_create :send_welcome_email

  private

  def send_welcome_email
    UserMailer.with(user: self).welcome_email.deliver_later
  end

end
```

3. While this does work, some problems with this approach begin to emerge. Testing becomes more of a hassle as every
   time a test user is created, all this other stuff happens. A solution to this is moving all of the email sending code
   into the controller.

```ruby

class UsersController < ApplicationController

  def create
    @user = User.new(user_params)
    if @user.save
      UserMailer.with(user: @user).welcome_email.deliver_later
      redirect_to dashboard_path, notice: "Welcome to our app!"
    else
      render(:new)
    end
  end

end
```

4. Now, perhaps it is decided a while later that user signups should be tracked as a analytics event in KissMetrics, and
   that we want to add all of our new users to a Mailchimp mailing list. No problem, we can add this code to the
   controller

```ruby

class UsersController < ApplicationController

  def create
    @user = User.new(user_params)
    if @user.save
      UserMailer.with(user: @user).welcome_email.deliver_later
      track_analytics_event(:signup, @user)
      MailchimpApi.delay.add_to_list(
        ENV['MAILCHIMP_CUSTOMER_LIST_ID'],
        @user.email
      @user.created_at.to_s(:mailchimp_date)
      )
      redirect_to dashboard_path, notice: "Welcome to our app!"
    else
      render(:new)
    end
  end

end
```

5. Next, want to allow users to sign up from our Hootsuite app via the API. We will have to duplicate the logic in
   another Users controller in the API namespace. We could work around this by extracting the code into a controller
   concern and include that in both controllers for code reuse.

   We now have an increasingly complicated process for signup, and the only way to test it is via controller tests. And
   these tests are slow to run and tricky to set up because we need to handle all the dependencies on Mailers,
   analytics, and Mailchimp.

```ruby

module Api
  module V1
    module HootsuiteApp
      class UsersController < ApplicationController

        def create
          @user = User.new(user_params)
          if @user.save
            UserMailer.with(user: @user).welcome_email.deliver_later
            track_analytics_event(:signup, @user)
            MailchimpApi.delay.add_to_list(
              ENV['MAILCHIMP_CUSTOMER_LIST_ID'],
              @user.email,
              @user.created_at.to_s(:mailchimp_date)
            )
            redirect_to dashboard_path, notice: "Welcome to our app!"
          else
            render(:new)
          end
        end

      end
    end
  end
end
```

6. Now, A little later we are running an AppSumo campaign and we need to import their 200 users into the app. We want to
   send them a special welcome email. I need a console script, and I’m duplicating the controller code again.

```ruby
# production console
users_attrs = [{ email: "name@email.com", name: "name", password: "passw123" }, ...]

users_attrs.each do |user_attrs|
  puts user_attrs[:email]
  user = User.create(user_attrs)
  next unless user.valid?

  UserMailer.with(user: user).special_welcome_email.deliver_later
  track_analytics_event(:signup, user)
  MailchimpApi.delay.add_to_list(
    ENV['MAILCHIMP_CUSTOMER_LIST_ID'],
    @user.email,
    @user.created_at.to_s(:mailchimp_date)
  )
end
```

7. Fast forward a few more iterations, and now I am reluctant to make any more changes to the user signup process.
   Behavior is now spread across various ActiveRecord callbacks, and methods in controllers, models, and concerns. I’ve
   lost clarity on what happens when a user signs up. I’m not able to respond to specific needs that deviate from the
   one-size-fits-all implementation we currently have. The app has become brittle and hard to change.

### Lets see if interactions can help us get a better handle on our application's behaviour

- Software code has two wings: data and behavior. Rails has a great story and strong conventions around data with
  ActiveRecord. We have models, associations, tables, and attributes for all our entities. These are the nouns in our
  grammar.
  However, Rails has no clear answer for behavior. Let’s define what I mean with app behavior: It’s the useful stuff
  that your app does like
  - Create and update data
  - Send emails
  - Export files
  - Interact with other apps via APIs
  - Recommend relevant articles
  - Make websites
  - etc.

  There are many options for implementing behavior in Rails, however there is no clear convention. And the result is
  confusion and less than optimal implementations.

- You can put behavior in the controller
  - But then it’s only available during the HTTP request cycle. And it’s not available in models, scripts, in the
    console, or in tests.
  - And you’ll end up duplicating code if controllers for the same resource exist in different workspaces. In our
    example app it was user signup in-app vs. signup in Hootsuite via API. You can mitigate duplication somewhat with
    concerns.

Interactions are the missing Rails convention around behavior.
We have looked at a number of solutions, and we like the ActiveInteraction RubyGem best. ActiveInteraction gives you a
place to put your business logic. It also helps you write safer code by validating that your inputs conform to your
expectations. **If ActiveRecord deals with your nouns, then ActiveInteraction handles your verbs.**

So what are the benefits of using interactions?

- You can encapsulate behavior
  - They allow you to simply and robustly invoke a behaviour in diverse contexts, e.g., controllers, models, tests, rake
    tasks, or consoles.
  - They clearly document the interface for a business operations. You go to the interactions folder to see all the
    interesting behavior. And each interaction tells you exactly what inputs it needs, and what it returns.
  - If you wrap a 3rd party service, then you can swap it out in a single place as needed. E.g., for testing, or if you
    want to replace the implementation.

- You can compose behavior
  - You can nest interactions very easily because they have standardized interfaces for invocation, input arguments,
    return values, and error handling.
  - You can implement complex domain behaviours by composing simple sub tasks into higher level processes.

- You can handle errors consistently
  - They provide good error messages.
  - The caller can decide how to deal with unexpected outcomes: raise an exception, display a warning, change the
    execution flow, or ignore it.

- You can test and debug more simply
  - Complex behaviors can now be tested via unit tests.
  - Test data setup is a breeze because now you have a tool for setting up almost every test case.
  - You can print every interaction invocation with its inputs, outcome, and return value during runtime to help with
    debugging.

Ok, time to look at some code that uses interactions. We're going to re-implement the opening examples for user signup,
but this time using interactions.

1. We start with a basic interaction to create a user.
  - The interaction file is located at app/interactions/public/users/create.rb. Our documentation contains good tips for
    naming conventions.
  - We first specify the input filters. They will check for the presence and correct type of each input argument. They
    can do type casting if needed, and provide default values. Here we expect three string arguments for email, name,
    and password.
  - Then you see input data validations using standard ActiveModel validations. These will be applied to the input
    arguments. Execution will stop if there are any validation errors.
  - And finally we have the execute method where we implement the behavior. This method is called only if all inputs are
    present and valid.
  - In the execute method we have access to the errors collection.
  - We then halt execution if there are any errors.
  - Only if everything has worked as expected so far, do we cause the additional side effects of sending emails, etc.
  - Then we return the newly created user.

```ruby
# app/interactions/public/users/create.rb
module Public
  module Users
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
        errors.merge!(user.errors) unless user.save
        halt_if_errors!

        UserMailer.with(user: user).welcome_email.deliver_later
        track_analytics_event(:signup, user)
        MailchimpApi.delay.add_to_list(
          ENV['MAILCHIMP_CUSTOMER_LIST_ID'],
          user.email,
          user.created_at.to_s(:mailchimp_date)
        )

        user
      end

    end
  end
end
```

2. This is how we invoke the Interaction from the controller:
   We call it with the user params. Notice that we’re not using StrongParameters. The interaction knows which arguments
   are allowed and will validate them in a much more powerful way than StrongParameters can do. We assign the return
   value to `outcome` and check if it has no errors. If there are errors we re-render the signup form and use the
   interaction itself as the form object. The interaction has public getters for all input arguments, and it implements
   the ActiveModel errors interface, so form errors will be displayed as expected. We can reuse the interaction code by
   invoking the same interaction from the Hootsuite API users controller.

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

3. Here we create 200 AppSumo users on the production console. It’s great when you have a very simple interface to
   trigger complex business behavior.

   As you can see, this is all pretty cool, however, there is one aspect we've glossed over so far that
   ActiveInteraction is not so great at. And that is when you have to re-render a new or edit form because of validation
   errors. Especially when the form needs access to non-trivial attributes on the form object, e.g., in Chinuk a user's
   sites, or in ContentGems a Filter’s parent folder. ActiveInteraction instances can serve as basic form objects. This
   will work in a lot of cases, however, they are not the actual ActiveRecord instance and don’t have access to
   associations or all model instance methods.

   We worked around this initially by adding more methods to the interactions to mimic the underlying ActiveRecord
   model’s interface, however, that did not really work.

```ruby 
# production console
users = [{email: "name@email.com", name: "the name", password: "password123"}, ...]
users.each do |user_attrs|
	Public::Users::Create.run!(user_attrs)
end
```

### Returning Interactions

After a lot of experimentation and discussion we think we found a solution: We created an ActiveInteraction variant that
handles form integration really well. We call it ReturningInteractions.

ReturningInteractions differ from regular ActiveInteractions in the invocation, input arguments, how they handle errors,
and what they return.

Returning interactions let us use proper ActiveRecord instances everywhere: in the controller, in the interaction, and
in the form if we need to re-render it.

1. Here is our signup interaction as a ReturningInteraction. I’ll point out some unique aspects in contrast to regular
   interactions:
  - The returning interaction inherits from a different parent class.
  - We specify the return value on line 6.
  - We added a new input filter: the :user ActiveRecord instance that will be created.
  - The execute method is now called execute_returning.
  - Halt_if_errors! Is renamed to return_if_errors! on line 15
  - The side effects at the end are identical to regular interactions.

This interaction is guaranteed to return the :user input argument, no matter if input values are not valid, or if we run
into any errors in the execute_returning! method. We know we’ll get back the :user instance. Any errors that emerged in
the interaction, or one of its delegated interactions, will be merged into the user instance so that they are available
when we re-render the form.

```ruby
# app/interactions/public/users/create.rb
module Public
  module Users
    class Create < ReturningInteraction

      returning :user

      record :user, class: User, default: -> { User.new }
      string :email
      string :name
      string :password

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

        user
      end

    end
  end
end
```

2. Here is an example of using a ReturningInteraction in a controller. It’s very similar to invoking a regular
   interaction.
  - Instead of :run we invoke it with :run_returning!, and we pass a user argument that is initialized to a new User
    record.
  - Notice how we don’t have to set up the form object in case of errors. The interaction is guaranteed to return the
    User instance.
  - Because it is a proper ActiveRecord instance, we can pass the return value to the re-rendered form, and we have
    access to all the ActiveRecord conveniences like associations, and all instance methods that exist on the model.

```ruby

module Public
  class UsersController < BaseController
    def create
      @user = ::Public::Users::Create.run_returning!(
        { user: User.new }.merge(params[:user].to_unsafe_hash),
      )
      if @user.errors_any?
        render(:new)
      else
        redirect_to dashboard_path, notice: "welcome to our app!"
      end
    end

  end
end
```

You may be wondering when to use regular vs returning interactions.
A good general rule is to use returning interactions for Rails form integration. And regular interactions for everything
else.

I hope that you can see the value of using interactions.
