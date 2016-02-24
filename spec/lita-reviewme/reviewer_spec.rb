require "spec_helper"

describe LitaReviewme::Reviewer do
  let(:github_username) { 'johnallen3d' }
  let(:chat_handle) { 'john.allen' }

  subject { described_class.new(github_username) }

  it "uses the github username when serialized to string" do
    expect(subject.to_s).to eq(github_username)
  end

  it "exposes the provided key" do
    expect(subject.key).to eq(github_username)
  end

  it "exposes the github username" do
    expect(subject.github_username).to eq(github_username)
  end

  describe "chat handle include" do
    subject { described_class.new("#{github_username}:#{chat_handle}") }

    it "parses the github username from the compound key" do
      expect(subject.github_username).to eq(github_username)
    end

    it "parses the chat handle from the compound key" do
      expect(subject.chat_handle).to eq(chat_handle)
    end
  end
end
