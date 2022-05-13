**Here is a User Signup interaction**

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
        errors.merge!(user.errors) unless user.update(inputs.except(:user))
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
**Here is a User Signup interaction**

The interaction file is located at app/interactions/public/users/create.rb. Our documentation contains good tips for naming conventions.
We first specify the input filters. They will check for the presence and correct type of each input argument. They can do type casting if needed, and provide default values. 

Here we expect three string arguments for email, name, and password.
Then you see input data validations using standard ActiveModel validations. These will be applied to the input arguments. Execution will stop if there are any validation errors.
And finally we have the execute method where we implement the behavior. 

This method is called only if all inputs are present and valid.
In the execute method we have access to the errors collection on line 19.
On line 20 we halt execution if there are any errors.
Only if everything has worked as expected so far, do we cause the additional side effects of sending emails, etc.
Then we return the newly created user.
