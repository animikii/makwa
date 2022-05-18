# Run Returning Interactions

### Example: Reseting Database App

```ruby
module DataApp
  module DbAppStructure
    # Resets the Database App to the initial state, removing all custom DbTales and DbWorkspaces
    class ResetDataApp < DataApp::DbInteraction
      
      string :i_user_id # uuid
      
      # @return [Hash] the new nw_patch_effects state
      def execute
        db_patch = DataApp::DbPatch.find_or_create_current
        if db_patch.has_pending_changes?
          errors.add(:base, "There are pending DbPatchItems.")
          return
        end
        # Remove custom NwTales
        DataApp.db_config.dig(:db_tales, :entries).keys.map(&:to_s).each do |db_table_id|
          next if CORE_DB_TABLE_IDS.include?(db_table_id)
          DataApp::DbAppStructure::DbPatchItems::Create.run_returning!(
            {
              db_patch_item: db_patch.db_patch_items.build,
              form_params: {suject_id::db_tale_id, suject_operation: "remove"}
            }
          )
        end
        # Remove custom NwWorkspaces
        DataApp.db_config.dig(:db_workspaces, :entries).keys.map(&:to_s).each do |db_workspace_id|
          next if CORE_NW_WORKSPACE_IDS.include?(db_workspace_id)
          DataApp::DbAppStructure::DbPatchItems::Create.run.returning!(
            {
              db_patch_item: db_patch.db_patch_items.build,
              form_params: {suject_id: db_workspace_id, subject_operation: "remove"}
            }
          )
        end
        # Apply the patch
        DataApp::DbAppStructure::DbPatches::Apply.run!(id: db_patch.id, i_user_id: i_user_id)
        # Ensure that all required access control data is present
        DataApp::DbInstaller::IUserAndPermissions::CreateSeedData.run!
      end
    end
  end
end
```

**Here is an example of composing simple Interactions into higher-level, complex business operations.** In Niiwin we have a function that resets the entire app and removes all customizations. We used this feature extensively during development.

- This slide shows the essence of the interaction that performs this task. It delegates to four lower-level interactions that may in turn delegate to further even lower-level interactions.
- Because of the standardized API, error handling is taken care of, and lower-level errors will bubble to the top.
- You can reset the entire app by invoking a single interaction in any context: in controllers, scripts, or tests.
