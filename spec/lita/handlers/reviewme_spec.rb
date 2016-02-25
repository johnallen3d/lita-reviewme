require "spec_helper"
require "ostruct"

describe Lita::Handlers::Reviewme, lita_handler: true do
  it { is_expected.to route_command("add iamvery to reviews").to :add_reviewer }
  it { is_expected.to route_command("add reviewer iamvery").to :add_reviewer }
  it { is_expected.to route_command("remove iamvery from reviews").to :remove_reviewer }
  it { is_expected.to route_command("remove reviewer iamvery").to :remove_reviewer }
  it { is_expected.to route_command("reviewers").to :display_reviewers }
  it { is_expected.to route_command("review me").to :generate_assignment }
  it { is_expected.to route_command("review https://github.com/user/repo/pull/123").to :comment_on_github }
  it { is_expected.to route_command("review <https://github.com/user/repo/pull/123>").to :comment_on_github }
  it { is_expected.to route_command("review https://github.com/user/repo/issues/123").to :comment_on_github }
  it { is_expected.to route_command("review https://bitbucket.org/user/repo/pull-requests/123").to :mention_reviewer }
  it { is_expected.to route_command("review <https://bitbucket.org/user/repo/pull-requests/123>").to :mention_reviewer }

  let(:reply) { replies.last }

  describe "#add_reviewer" do
    it "adds a name to the list" do
      send_command("add iamvery to reviews")

      expect(reply).to eq("added iamvery to reviews")
    end

    it "accepts a chat handle if provided" do
      send_command("add johnallen3d:john.allen to reviews")

      expect(reply).to eq("added johnallen3d (@john.allen) to reviews")
    end
  end

  describe "#remove_reviewer" do
    before do
      send_command("add iamvery to reviews")
      send_command("add johnallen3d:john.allen to reviews")
    end

    it "removes a name from the list" do
      send_command("remove iamvery from reviews")

      expect(reply).to eq("removed iamvery from reviews")
    end

    it "removes a name when we have chat handle" do
      send_command("remove johnallen3d from reviews")

      expect(reply).to eq("removed johnallen3d from reviews")
    end
  end

  describe "#generate_assignment" do
    it "responds with the next reviewer's name" do
      send_command("add iamvery to reviews")
      send_command("review me")

      expect(reply).to eq("iamvery")
    end

    it "rotates the response each time" do
      send_command("add iamvery to reviews")
      send_command("add zacstewart to reviews")

      send_command("review me")
      expect(replies.last).to eq("iamvery")

      send_command("review me")
      expect(replies.last).to eq("zacstewart")
    end
  end

  describe "#comment_on_github" do
    let(:repo) { "gh_user/repo" }
    let(:id) { "123" }
    let(:user) { OpenStruct.new({ id: 'abc' }) }
    let(:pr) do
      OpenStruct.new({ user: OpenStruct.new({ login: "pr-owner" }) })
    end

    before do
      # Prevent hitting the network for PR info.
      allow_any_instance_of(Octokit::Client).to receive(:pull_request)
        .and_return(pr)
    end

    it "posts comment on github" do
      expect_any_instance_of(Octokit::Client).to receive(:add_comment)
        .with(repo, id, ":eyes: @iamvery")

      send_command("add iamvery to reviews")
      send_command("review https://github.com/#{repo}/pull/#{id}")

      expect(reply).to eq("iamvery should be on it...")
    end

    it "messages the reviewer in chat if handle is present" do
      allow_any_instance_of(Octokit::Client).to receive(:add_comment)
      allow(Lita::User).to receive(:find_by_mention_name).and_return(user)

      expect_any_instance_of(Lita::Robot).to receive(:send_message)

      send_command("add johnallen3d:john.allen to reviews")
      send_command("review https://github.com/#{repo}/pull/#{id}")
    end

    it "skips assigning to the GitHub PR owner" do
      expect_any_instance_of(Octokit::Client).to receive(:pull_request)
        .with(repo, id).and_return(pr)

      expected_reviewer = 'NOT THE PR OWNER'
      expect_any_instance_of(Octokit::Client).to receive(:add_comment)
        .with(repo, id, ":eyes: @#{expected_reviewer}")

      send_command("add #{pr.user.login} to reviews")
      send_command("add #{expected_reviewer} to reviews")
      send_command("review https://github.com/#{repo}/pull/#{id}")

      expect(reply).to eq("#{expected_reviewer} should be on it...")
    end

    it "handles errors gracefully" do
      expect_any_instance_of(Octokit::Client).to receive(:add_comment)
        .and_raise(Octokit::Error)

      url = "https://github.com/iamvery/lita-reviewme/pull/5"

      send_command("add iamvery to reviews")
      send_command("review #{url}")

      expect(reply).to eq("I couldn't post a comment. (Are the permissions right?) iamvery: :eyes: #{url}")
    end
  end

  describe "#display_reviewers" do
    it "responds with list of reviewers" do
      send_command("add iamvery to reviews")
      send_command("add zacstewart to reviews")
      send_command("reviewers")

      expect(reply).to include("zacstewart, iamvery")
    end
  end

  describe "#mention_reviewer" do
    it "mentions a reviewer in chat with the given URL" do
      send_command("add iamvery to reviews")
      send_command("review https://bitbucket.org/user/repo/pull-requests/123")
      expect(replies.last).to eq("iamvery: :eyes: https://bitbucket.org/user/repo/pull-requests/123")
    end
  end
end
