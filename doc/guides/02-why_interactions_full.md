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

2. Now, a new requirement emerges: We want to send a welcome email to all new users. We can use an ActiveRecord callback on the User model. `after_create`  will make this happen magically!

```ruby
class User < ApplicationRecord

	after_create :send_welcome_email

	private

	def send_welcome_email
		UserMailer.with(user: self).welcome_email.deliver_later
	end

end
```

3. While this does work, some problems with this approach begin to emerge. Testing becomes more of a hassle as every time a test user is created, all this other stuff happens. A solution to this is moving all of the email sending code into the controller.

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

4. Now, perhaps it is decided a while later that user signups should be tracked as a analytics event in KissMetrics, and that we want to add all of our new users to a Mailchimp mailing list. No problem, we can add this code to the controller

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

5. Next, want to allow users to sign up from our Hootsuite app via the API. We will have to duplicate the logic in another Users controller in the API namespace. We could work around this by extracting the code into a controller concern and include that in both controllers for code reuse.

	We now have an increasingly complicated process for signup, and the only way to test it is via controller tests. And these tests are slow to run and tricky to set up because we need to handle all the dependencies on Mailers, analytics, and Mailchimp.

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