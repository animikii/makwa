# Example 1: Standard Interaction
# This example interaction is used to generate locale files in a Niiwin app. It writes the files to disk and marks them to be committed to git:

# app/interactions/niiwin/nw_code_generator/nw_managed_code/locales.rb
module Niiwin
  module NwCodeGenerator
    module NwManagedCode
      # Generates <niiwin_app>/config/locales/<locale>_managed_by_niiwin.yml
      class Locales < ApplicationInteraction

        hash :nw_patch_effects, strip: false

        # @return [Hash] the updated nw_patch_effects
        def execute
          @nw_patch_effects = nw_patch_effects.deep_symbolize_keys # ActiveInteraction stringifies keys
          generate_locales
          @nw_patch_effects
        end

        protected

        def generate_locales
          Niiwin.nw_config.dig(:nw_base, :nw_locales).each do |nw_locale|
            locale_filename = build_filename(nw_locale)
            File.write(locale_filename, build_file_contents(nw_locale))
            @nw_patch_effects[:commit_files_to_git] << locale_filename
          end
        end

        # @param nw_locale [String] the locale string, e.g., "en"
        def build_filename(nw_locale)
          File.join(Rails.root, "config", "locales", "#{nw_locale}_managed_by_niiwin.yml")
        end

        # @param nw_locale [String] the locale string, e.g., "en"
        # @return [String] the locale file contents
        def build_file_contents(nw_locale)
          # ... (skipping the details)
        end

      end
    end
  end
end
