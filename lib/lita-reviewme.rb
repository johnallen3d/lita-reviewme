require "lita"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "lita-reviewme/github"

require "lita/handlers/reviewme"

module Lita
  module Reviewme
    class NoReviewer < StandardError; end
    class UnknownOwner < StandardError; end
    class CannotPostComment < StandardError; end
  end
end
