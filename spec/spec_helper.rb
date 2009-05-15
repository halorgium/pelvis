require 'rubygems'

require File.dirname(__FILE__) + '/../lib/pelvis'
require 'pelvis/protocols/xmpp'

class TestDelegate
  include Pelvis::Delegate

  def initialize(stop_on_complete=true)
    @data = []
    @stop = stop_on_complete
  end
  attr_reader :data

  def completed?
    @completed
  end

  def errored?
    @errored
  end

  def receive(data)
    @data << data
  end

  def complete(event)
    @completed = event
    EM.stop if @stop
  end

  def error(event)
    @errored = error
    EM.stop
  end
end

class Simple < Pelvis::Actor
  operation "/number" do
    invocation.receive(args)
    invocation.complete("awesome")
  end
end

require File.dirname(__FILE__) + '/helpers'

Pelvis.logger.level = Logger::ERROR
