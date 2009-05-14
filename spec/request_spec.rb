require File.dirname(__FILE__) + '/spec_helper'

describe "A request on pelvis" do
  include Pelvis::Helpers

  it "works" do
    agents = [
      [:foo, [Simple]],
      [:bar],
    ]

    results = TestDelegate.new
    EM.run do
      agent_start(agents) do |agent|
        agent.request(:all, "/number", {}, :identities => [identity_for(:foo)], :delegate => results)
      end
    end
    results.data.should == [{"number" => 1}]
    results.should be_completed
    results.should_not be_errored
  end
end
