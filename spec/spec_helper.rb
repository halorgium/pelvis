require 'rubygems'

require File.dirname(__FILE__) + '/../lib/pelvis'
require 'pelvis/protocols/xmpp'

class TestDelegate
  include Pelvis::SafeDelegate

  def initialize(stop_on_complete=true)
    @data = []
    @stop = stop_on_complete
  end
  attr_reader :data

  def completed?
    @completed
  end

  def failed?
    @failed
  end

  def received(data)
    @data << data
  end

  def completed(event)
    @completed = event
    EM.stop # if @stop
  end

  def failed(error)
    @failed = error
    EM.stop
  end
end

class Resourced < Pelvis::Actor
  operation "/w_resource", :stuff
   
  def self.resources
    ['/howdy']
  end

  def stuff
    send_data 'message' => 'howdy'
    finish
  end
end

class Simple < Pelvis::Actor
  operation "/echo", :echo
  
  def echo
    send_data params
    finish
  end
end

require File.dirname(__FILE__) + '/helpers'

Pelvis.logger.level = Logger::ERROR
