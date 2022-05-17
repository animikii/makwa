# Run Returning Interactions

### Example: Reseting Niiwin App

```ruby
module Niiwin
  module NwAppStructure
    # Resets the Niiwin App to the initial state, removing all custom NwTales and NwWorkspaces
    class ResetNiiwinApp < Niiwin::NwInteraction
      
      string :i_user_id # uuid
      
      # @return [Hash] the new nw_patch_effects state
      def execute
        nw_patch = Niiwin::NwPatch.find_or_create_current
        if nw_patch.has_pending_changes?
          errors.add(:base, "There are pending NwPatchItems.")
          return
        end
        # Remove custom NwTales
        Niiwin.nw_config.dig(:nw_tales, :entries).keys.map(&:to_s).each do |nw_table_id|
          next if CORE_NW_TABLE_IDS.include?(nw_table_id)
          Niiwin::NwAppStructure::NwPatchItems::Create.run_returning!(
            {
              nw_patch_item: nw_patch.nw_patch_items.build,
              form_params: {suject_id: nw_tale_id, suject_operation: "remove"}
            }
          )
        end
        # Remove custom NwWorkspaces
        Niiwin.nw_config.dig(:nw_workspaces, :entries).keys.map(&:to_s).each do |nw_workspace_id|
          next if CORE_NW_WORKSPACE_IDS.include?(nw_workspace_id)
          Niiwin::NwAppStructure::NwPatchItems::Create.run.returning!(
            {
              nw_patch_item: nw_patch.nw_patch_items.build,
              form_params: {suject_id: nw_workspace_id, subject_operation: "remove"}
            }
          )
        end
        # Apply the patch
        Niiwin::NwAppStructure::NwPatches::Apply.run!(id: nw_patch.id, i_user_id: i_user_id)
        # Ensure that all required access control data is present
        Niiwin::NwInstaller::IUserAndPermissions::CreateSeedData.run!
      end
    end
  end
end
```

**Here is an example of composing simple Interactions into higher level, complex business operations.** In Niiwin we have a function that resets the entire app and removes all customizations. We used this feature extensively during development.

- This slide shows the essence of the interaction that performs this task. It delegates to four lower level interactions that may in turn delegate to further even lower level interactions.
- Because of the standardized API, error handling is taken care of, and lower level errors will bubble to the top.
- You can reset the entire app by invoking a single interaction in any context: in controllers, scripts, or tests.
