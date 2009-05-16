class Xen < Pelvis::Agent

  def self.resources
    ['/cluster/ey/1/slice/10','/cluster/ey/1/slice/15']
  end

  operation '/slice/stop'
  def stop
  end
  
  operation '/slice/start'
  def start
  end
end
