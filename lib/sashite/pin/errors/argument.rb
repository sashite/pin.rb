# frozen_string_literal: true

require_relative "argument/messages"

module Sashite
  module Pin
    module Errors
      # Error raised when PIN parsing or validation fails.
      class Argument < ::ArgumentError
      end
    end
  end
end
