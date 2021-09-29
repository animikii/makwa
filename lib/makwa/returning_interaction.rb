# frozen_string_literal: true

module Makwa
  # @abstract Override {#execute_returning} and call {#returning} in the class body, passing in the symbol
  #   of the input you want returned. Guaranteed to return the returning input, with interaction errors
  #   merged into it.
  class ReturningInteraction < ::Makwa::Interaction
    class ReturnFilterInexistent < StandardError; end

    class ReturningFilterNotSpecified < StandardError; end

    class NotActiveModelErrorable < StandardError; end

    define_callbacks(:execute_returning)

    class << self
      # @param (see ActiveInteraction::Runnable#initialize)
      #
      # @return (see ReturningInteraction#run_returning!)
      def run_returning!(*args)
        new(*args).send(:run_returning!)
      end

      # @param return_filter [Symbol] Name of the input filter to be returned
      def returning(return_filter)
        @return_filter = return_filter
      end
    end

    # @abstract
    #
    # @raise [NotImplementedError]
    def execute_returning
      raise NotImplementedError, "You need to implemented the method #execute_returning in your interaction."
    end

    private

    # @return [Object]
    def run_returning!
      @_interaction_result = return_input # {#result=} has side-effects
      raise ReturningFilterNotSpecified unless self.class.instance_variable_defined?(:@return_filter)
      raise ReturnFilterInexistent unless result
      raise NotActiveModelErrorable unless result.respond_to?(:errors) && result.errors.respond_to?(:merge!)

      # Run validations (explicitly, don't rely on #valid?), add any errors to result, and return result if errors exist
      validate
      return result.tap { |r| r.errors.merge!(errors) } if errors_any?

      # Otherwise run the body of the interaction (along with any callbacks) ...
      # run_callbacks(:execute_returning) { execute_returning }
      run_callbacks(:execute_returning) do
        execute_returning
      rescue ::Makwa::Interaction::Interrupt
        # Do nothing
      end

      # ... and return the result, merging in any errors added in the body of the interaction that are not duplicates.
      # Duplicates would occur if, for example, the body of the interaction calls
      # `errors.merge!(<returning_filter>.errors)` as is often done in non-returning interactions.
      result.tap do |r|
        errors.each do |e|
          r.errors.add(e.attribute, e.message) unless r.errors.added?(e.attribute, e.message)
        end
      end
    end

    # @return [Object]
    def return_input
      @return_input ||= inputs[self.class.instance_variable_get(:@return_filter)]
    end

    # @param other [Class] The other interaction.
    #
    # @return (see #result)
    def compose(other, *args)
      @_interaction_result = other.run_returning!(*args)

      if block_given?
        errors.merge!(@_interaction_result.errors)
        yield @_interaction_result
      end

      @_interaction_result
    rescue NotImplementedError
      super(other, *args)
    end
  end
end
