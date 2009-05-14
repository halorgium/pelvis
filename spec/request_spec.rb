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
        agent.request(:all, "/number", {:number => 1, :hash => { :one => 2 }}, :identities => [identity_for(:foo)], :delegate => results)
      end
    end
    results.should be_completed
    results.should_not be_errored

    results.data.size.should == 1
    res = results.data.first
    res.should be_a_kind_of(Pelvis::Message)
    res.data.should == { 'number' => 1, 'hash' => { 'one' => 2 } }
  end
end
