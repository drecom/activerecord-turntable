module ActiveRecord::Turntable::ActiveRecordExt
  module CleverLoad
    extend ActiveSupport::Concern

    included do
      ActiveRecord::VERSION::STRING < '3.1' ?
        include(AR30):
        include(AR31)

      class << ActiveRecord::Base
        delegate :clever_load!, :to => :scoped
      end
    end

    module AR30
      def clever_load!(association_name)
        # load records
        records = self.to_a
        klass = records.first.class
        reflection = klass.reflections[association_name]

        if reflection
          foreign_class = reflection.klass
          foreign_objects = case reflection.macro
                            when :has_one
                              foreign_class.where(reflection.primary_key_name => records.map(&reflection.association_primary_key.to_sym).uniq)
                            when :belongs_to
                              foreign_class.where(reflection.association_primary_key => records.map(&reflection.primary_key_name.to_sym).uniq)
                            else
                              []
                            end

          self.each do |obj|
            matched_object = case reflection.macro
                             when :has_one
                               foreign_objects.find {|fo|
                                 obj.send(reflection.association_primary_key) == fo.send(reflection.primary_key_name)
                               }
                             when :belongs_to
                               foreign_objects.find {|fo|
                                 obj.send(reflection.primary_key_name) == fo.send(reflection.association_primary_key)
                               }
                             end
            association_proxy = obj.send("set_#{reflection.name}_target", matched_object)
            # TODO: set reverse_instance
            # association_proxy.send(:set_inverse_instance, matched_object, obj)
          end
        end
        records
      end
    end

    module AR31
      def clever_load!(association_name)
        # load records
        records = self.to_a
        klass = records.first.class
        reflection = klass.reflections[association_name]

        if reflection
          foreign_class = reflection.klass
          foreign_objects = case reflection.macro
                            when :has_one
                              foreign_class.where(reflection.foreign_key => records.map(&reflection.association_primary_key.to_sym).uniq)
                            when :belongs_to
                              foreign_class.where(reflection.association_primary_key => records.map(&reflection.foreign_key.to_sym).uniq)
                            else
                              []
                            end

          self.each do |obj|
            matched_object = case reflection.macro
                             when :has_one
                               foreign_objects.find {|fo|
                                 obj.send(reflection.association_primary_key) == fo.send(reflection.foreign_key)
                               }
                             when :belongs_to
                               foreign_objects.find {|fo|
                                 obj.send(reflection.foreign_key) == fo.send(reflection.association_primary_key)
                               }
                             end
            obj.association(association_name).target = matched_object
            obj.association(association_name).send(:set_inverse_instance, matched_object)
          end
        end
        records
      end
    end
  end
end
