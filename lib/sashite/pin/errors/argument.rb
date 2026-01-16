# frozen_string_literal: true

require_relative "argument/messages"

module Sashite
  module Pin
    module Errors
      # Error raised when PIN parsing or validation fails.
      #
      # @example
      #   raise Argument, Argument::Messages::EMPTY_INPUT
      class Argument < ::ArgumentError
      end
    end
  end
end
