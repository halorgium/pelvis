require 'set'

class Herault < Pelvis::Actor
  def self.operation_map
    @operation_map ||= {}
  end

  operation "/security/advertise"
  def advertise
    identity = params[:identity]
    params[:operations].each do |operation|
      add_identity_for_operation(identity, operation)
    end
    finish
  end

  operation "/security/discover"
  def discover
    identities = identities_for(params[:operation])
    send_data :identities => identities if identities.any?
    finish
  end

  def add_identity_for_operation(identity, operation)
    self.class.operation_map[operation] ||= Set.new
    self.class.operation_map[operation] << identity
  end

  def identities_for(operation)
    self.class.operation_map[operation].to_a
  end
end
