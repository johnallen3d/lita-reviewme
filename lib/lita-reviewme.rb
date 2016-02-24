require "lita"
require "lita-reviewme/reviewer"

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "locales", "*.yml"), __FILE__
)]

require "lita/handlers/reviewme"
