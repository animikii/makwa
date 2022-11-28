# frozen_string_literal: true

module Makwa
  class Interaction < ::ActiveInteraction::Base
    class Interrupt < Object.const_get("::ActiveInteraction::Interrupt")
    end

    #
    # Safely checking for errors
    #

    # Use this instead of `outcome.invalid?` (which is destructive and clears errors)
    delegate :any?, to: :errors, prefix: true # def errors_any?
    # Use this instead of `outcome.valid?` (which is destructive and clears errors)
    delegate :empty?, to: :errors, prefix: true # def errors_empty?

    #
    # Halting of execution
    #

    # Exits early if there are any errors.
    def return_if_errors!
      raise(Interrupt, errors) if errors_any?
    end

    #
    # Logging interaction execution
    #

    # Log execution of interaction, caller, and inputs
    set_callback :filter, :before, ->(interaction) {
      debug("Executing interaction #{interaction.class.name} #{interaction.id_marker}")
      calling_interaction = interaction.calling_interaction
      debug(" ↳ called from #{calling_interaction} #{interaction.id_marker}") if calling_interaction.present?
      # The next two lines offer two ways of printing inputs: Either truncated, or full. Adjust as needed.
      # truncated_inputs = interaction.inputs.inspect.truncate_in_the_middle(2000, omission: "\n... [inputs truncated] ...\n")
      truncated_inputs = interaction.inputs.inspect
      debug(" ↳ inputs: #{truncated_inputs} #{interaction.id_marker}")
    }

    # Log interaction's outcome and errors if any.
    set_callback :execute, :after, ->(interaction) {
      if interaction.errors_empty?
        debug(" ↳ outcome: succeeded (id##{interaction.object_id})")
      else
        debug(" ↳ outcome: failed (id##{interaction.object_id})")
        debug(" ↳ errors: #{interaction.errors.details} (id##{interaction.object_id})")
      end
    }

    # @return [Array<String>] the callstack containing interactions only, starting with the immediate caller.
    def calling_interactions
      @calling_interactions ||= caller.find_all { |e|
        e.index("/app/interactions/") && !e.index(__FILE__) && !e.index("/returning_interaction.rb")
      }
    end

    # @return [String] the backtrace entry for the immediately calling interaction (first item in calling_interactions).
    def calling_interaction
      @calling_interaction ||= calling_interactions.first&.split("/interactions/")&.last || ""
    end

    # The standard method for all logging output. Turn this on for detailed interaction logging.
    def debug(txt)
      # puts indent + txt
    end

    # @return [String] a marker that identifies an interaction instance by its Ruby object_id. This is helpful
    #   when following an execution log with nested or interleaved interaction log lines.
    def id_marker
      "(id##{object_id})"
    end

    # @return [String] a prefix that indents each debug line according to the level of interactions nesting.
    def indent
      lvl = [0, calling_interactions.count].max
      "  " * lvl
    end
  end
end
