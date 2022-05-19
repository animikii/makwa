# Example: ReturningInteraction
# As an example we use a ReturningInteraction to update User records in the admin workspace

# app/controllers/public/usercontroller/basecontroller.rb
class UsersController < BaseController
  ...
    def update
      @user = Admin::Users::Update.run_returning!(
        { user: User.find(params[:id]) }
      )
      render(:edit) and return
    end
  ...
end

# app/interactions/public/users/update.rb
module Users
  class Update < ReturningInteraction

    returning :user

    record :user, class: User
    string :first_name
    string :last_name

    def execute_returning
      user.update(inputs.except(:user))
    end
  end
end


