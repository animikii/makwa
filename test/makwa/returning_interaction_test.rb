require "test_helper"

module Makwa
  class ReturningInteractionTest < ActiveSupport::TestCase
    # Class with minimal implementation of ActiveModelErrors interface
    # From https://www.rubydoc.info/docs/rails/ActiveModel/Errors
    class ImplementsActiveModelErrorsInterface
      # Required dependency for ActiveModel::Errors
      extend ActiveModel::Naming

      # Use this instead of `outcome.invalid?` (which is destructive and clears errors)
      delegate :any?, to: :errors, prefix: true # def errors_any?
      # Use this instead of `outcome.valid?` (which is destructive and clears errors)
      delegate :empty?, to: :errors, prefix: true # def errors_empty?

      def initialize
        @errors = ActiveModel::Errors.new(self)
      end

      # These are not part of the ActiveModel::Errors interface, they are mapped to interaction input arguments
      attr_accessor :boolean_attr
      attr_accessor :integer_attr
      attr_accessor :nested_hash_attr

      attr_accessor :name
      attr_reader :errors

      def validate!
        errors.add(:name, :blank, message: "cannot be nil") if name.nil?
      end

      # The following methods are needed to be minimally implemented

      def read_attribute_for_validation(attr)
        send(attr)
      end

      def self.human_attribute_name(attr, _options = {})
        attr
      end

      def self.lookup_ancestors
        [self]
      end
    end

    # This is the ReturningInteraction we're testing
    class ReturningInteractionUnderTest < Makwa::ReturningInteraction
      returning :returned_record

      record :returned_record, class: ImplementsActiveModelErrorsInterface

      boolean :boolean_attr
      integer :integer_attr
      hash :nested_hash_attr, strip: false, default: {}

      def execute_returning
        returned_record.boolean_attr = boolean_attr
        returned_record.integer_attr = integer_attr
        returned_record.nested_hash_attr = nested_hash_attr.symbolize_keys
      end
    end

    test "Has no errors with valid inputs" do
      returned_record = ReturningInteractionUnderTest.run_returning!(
        returned_record: ImplementsActiveModelErrorsInterface.new,
        boolean_attr: true,
        integer_attr: 42,
        nested_hash_attr: {a: 1, b: true, c: "abc"}
      )
      puts(returned_record.errors.details) if returned_record.errors_any?
      assert(returned_record.errors_empty?)
      assert_equal(true, returned_record.boolean_attr)
      assert_equal(42, returned_record.integer_attr)
      assert_equal({a: 1, b: true, c: "abc"}, returned_record.nested_hash_attr)
    end

    test "Has errors with invalid inputs" do
      returned_record = ReturningInteractionUnderTest.run_returning!(
        returned_record: ImplementsActiveModelErrorsInterface.new,
        boolean_attr: 42,
        integer_attr: true,
        nested_hash_attr: "abc"
      )
      assert(returned_record.errors_any?)
      assert_equal(
        {
          boolean_attr: [{error: :invalid_type, type: "boolean"}],
          integer_attr: [{error: :invalid_type, type: "integer"}],
          nested_hash_attr: [{error: :invalid_type, type: "hash"}]
        },
        returned_record.errors.details
      )
    end
  end
end
