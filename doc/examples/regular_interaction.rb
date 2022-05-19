# Example: Standard Interaction
# This example interaction is used to generate locale files in a database app. It writes the files to disk and marks them to be committed to git:

# app/interactions/database_app/app_code_generator/app_managed_code/locales.rb
module DataApp
  module CodeGenerator
    module AppManagedCode
      # Generates <db_app>/config/locales/<locale>_managed_by_app.yml
      class Locales < ApplicationInteraction

        hash :app_patch_effects, strip: false

        # @return [Hash] the updated app_patch_effects
        def execute
          @app_patch_effects = app_patch_effects.deep_symbolize_keys # ActiveInteraction stringifies keys
          generate_locales
          @app_patch_effects
        end

        protected

        def generate_locales
          DataApp.app_config.dig(:app_base, :app_locales).each do |app_locale|
            locale_filename = build_filename(app_locale)
            File.write(locale_filename, build_file_contents(app_locale))
            @app_patch_effects[:commit_files_to_git] << locale_filename
          end
        end

        # @param app_locale [String] the locale string, e.g., "en"
        def build_filename(app_locale)
          File.join(Rails.root, "config", "locales", "#{app_locale}_managed_by_app.yml")
        end

        # @param app_locale [String] the locale string, e.g., "en"
        # @return [String] the locale file contents
        def build_file_contents(app_locale)
          # ... (skipping the details)
        end

      end
    end
  end
end
