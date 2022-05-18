# Example: ReturningInteraction
# As an example we use a ReturningInteraction to update User records in the admin workspace

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


