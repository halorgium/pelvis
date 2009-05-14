require File.dirname(__FILE__) + '/spec_helper'

describe "A request on pelvis" do
  include Pelvis::Helpers

  def simple_start(&block)
    agents = [
      [:foo, [Simple]],
      [:bar],
    ]

    agent_start(agents, &block)
  end

  before(:each) do
    @results = TestDelegate.new
  end

  it "works" do
    simple_start do |agent|
      agent.request(:all, "/number", {}, :identities => [identity_for(:foo)], :delegate => @results)
    end

    @results.data.should == [{"number" => 1}]
    @results.should be_completed
    @results.should_not be_errored
  end
end
