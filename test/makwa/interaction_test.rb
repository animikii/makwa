require "test_helper"

module Makwa
  class InteractionTest < ActiveSupport::TestCase
    DEFAULT_STRING_INPUT = "default value"
    DEFAULT_SUFFIX = "-suffix"

    class InteractionUnderTest < Makwa::Interaction
      string :string_input, default: DEFAULT_STRING_INPUT

      def execute
        errors.add(:string_input, "must contain 'value'") unless string_input.index("value")
        return_if_errors!

        string_input + DEFAULT_SUFFIX
      end
    end

    class OuterInteractionForComposeTest < Makwa::Interaction
      string :string_input

      def execute
        compose(InteractionUnderTest, inputs)
      end
    end

    test "responds to #errors_any?" do
      outcome = InteractionUnderTest.run
      assert_equal(false, outcome.errors_any?)
    end

    test "responds to #errors_empty?" do
      outcome = InteractionUnderTest.run
      assert(outcome.errors_empty?)
    end

    test "assigns default value to optional string_input" do
      outcome = InteractionUnderTest.run
      assert_equal(DEFAULT_STRING_INPUT + DEFAULT_SUFFIX, outcome.result)
    end

    test "uses given string_input" do
      custom_string_input = "custom value"
      outcome = InteractionUnderTest.run(string_input: custom_string_input)
      assert_equal(custom_string_input + DEFAULT_SUFFIX, outcome.result)
    end

    test "catches input validation errors" do
      outcome = InteractionUnderTest.run(string_input: 42)
      assert_equal(
        {string_input: ["is not a valid string"]},
        outcome.errors.to_hash
      )
    end

    test "catches errors added in #execute method" do
      outcome = InteractionUnderTest.run(string_input: "invalid string")
      assert_equal(
        {string_input: ["must contain 'value'"]},
        outcome.errors.to_hash
      )
    end

    test "implements #return_if_errors!" do
      outcome = InteractionUnderTest.run(string_input: "invalid string")
      assert(outcome.errors_any?)
      # In the error case, errors are returned as the result.
      assert_equal(outcome.errors, outcome.result)
    end

    test "merges errors from composed interactions" do
      outcome = OuterInteractionForComposeTest.run(string_input: "invalid string")
      assert_equal(
        {string_input: [{error: "must contain 'value'"}]},
        outcome.errors.details
      )
    end
  end
end
