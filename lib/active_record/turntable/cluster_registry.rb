module ActiveRecord::Turntable
  class ClusterRegistry < HashWithIndifferentAccess
    def release!
      values.each(&:release!)
    end
  end
end
