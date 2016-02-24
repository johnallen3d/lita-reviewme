module LitaReviewme
  class Reviewer
    attr_reader :key, :github_username, :chat_handle

    def initialize(key)
      @key = key
      @github_username, @chat_handle = key.split(':')
    end

    def to_s
      github_username
    end

    def self.from_response(response)
      new(response.matches.flatten.first)
    end
  end
end
