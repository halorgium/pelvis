require File.dirname(__FILE__) + '/spec_helper'
require 'examples/actors/herault'

describe "A request on pelvis" do
  include Pelvis::Helpers

  before(:each) do
    @agents = [
      [:herault,  [Herault]],
      [:foo,      [Simple]],
      [:bar,      []],
    ]
  end

  it "works when the identity is specified" do
    results = TestDelegate.new
    start_agents do |agent|
      agent.request(:direct, "/number", {:number => 1, :hash => { :one => 2 }}, :identities => [identity_for(:foo)], :delegate => results)
    end
    should_be_good(results)
  end

  it "discovers through herault when identities are not specified" do
    results = TestDelegate.new
    start_agents do |agent|
      agent.request(:all, "/number", {:number => 1, :hash => { :one => 2 }}, :delegate => results)
    end
    should_be_good(results)
  end

  it "errors when the remote end is down" do
    pending "This should call into the 'failed' callback"

    results = TestDelegate.new
    start_agents do |agent|
      agent.request(:direct, "/number", {:number => 1, :hash => { :one => 2 }}, :identities => ["broken"], :delegate => results)
    end
    should_be_good(results)
  end

  def should_be_good(results)
    results.should be_completed
    results.should_not be_failed

    results.data.size.should == 1
    res = results.data.first
    res.should == { 'number' => 1, 'hash' => { 'one' => 2 } }
  end
end
