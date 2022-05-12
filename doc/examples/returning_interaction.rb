# Example 2: ReturningInteraction
# As an example we use a ReturningInteraction to update User records in the admin workspace

# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < BaseController
    ...
      def update
        @user = Admin::Users::Update.run_returning!(
          { user: User.find(params[:id]) }.merge( # We pass in the User instance that will be updated.
            params.to_unsafe_h[:user]  # We skip strong_params, the interaction cleans up params.
          )
        )
        render(:edit) and return if @user.errors_any? # Notice use of #errors_any? vs. #invalid? (See below)

        redirect_to(admin_user_path(@user), notice: "User was updated successfully")
      end
    ...
  end
end

# The invoked interaction:

# app/interactions/admin/users/update.rb
module Admin
  module Users # This module uses plural to avoid naming conflict with ActiveRecord User class
    class Update < ReturningInteraction

      returning :user

      record :user, class: User          # Works with a User instance, or a user's database id.
      string :first_name
      string :last_name
      string :email                      # Validates presence of :email key, and type String for its value.
      string :password
      boolean :is_admin

      validate :email, presence: true    # ActiveModel validations can be used here.

      # @return [User] the user input argument.
      def execute_returning
        merge_errors!(user.errors) unless user.update(inputs.except(:user))
        return_if_errors! # Abort if there are any errors

        # Send email to user
        compose(Infrastructure::Emails::NotifyUserOfUpdate, user)
      end
    end
  end
