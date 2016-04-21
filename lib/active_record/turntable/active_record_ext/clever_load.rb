module ActiveRecord::Turntable
  module ActiveRecordExt
    module CleverLoad
      extend ActiveSupport::Concern

      included do
        class << ActiveRecord::Base
          delegate :clever_load!, to: :all
        end
      end

      def clever_load!(association_name)
        # load records
        records = self.to_a
        klass = records.first.class
        association_key = Util.ar42_or_later? ? association_name.to_s : association_name
        reflection = klass.reflections[association_key]

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
            obj.association(association_name).set_inverse_instance(matched_object) if matched_object
            obj.association(association_name).loaded!
          end
        end
        records
      end
    end
  end
end
