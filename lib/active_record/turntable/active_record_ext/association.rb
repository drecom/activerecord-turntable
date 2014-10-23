require 'active_record/associations'

module ActiveRecord::Turntable
  module ActiveRecordExt
    module Association
      extend ActiveSupport::Concern

      included do
        ActiveRecord::Associations::SingularAssociation.send(:include, SingularAssociationExt)
        ActiveRecord::Associations::CollectionAssociation.send(:include, CollectionAssociationExt)
        ActiveRecord::Associations::Builder::Association.valid_options += [:foreign_shard_key]
      end

      module SingularAssociationExt
        extend ActiveSupport::Concern

        included do
          alias_method_chain :find_target, :turntable
        end

        private

        def find_target_with_turntable
          current_scope = scope
          if should_use_shard_key?
            current_scope = current_scope.where(klass.turntable_shard_key => owner.send(foreign_shard_key))
          end
          if record = current_scope.take
            set_inverse_instance record
          end
        end
      end

      module CollectionAssociationExt
        extend ActiveSupport::Concern

        included do
          alias_method_chain :find_target, :turntable
        end

        private

        def find_target_with_turntable
          records =
            if options[:finder_sql]
              reflection.klass.find_by_sql(custom_finder_sql)
            else
              current_scope = scope
              if should_use_shard_key?
                current_scope = current_scope.where(klass.turntable_shard_key => owner.send(foreign_shard_key))
              end
              current_scope.to_a
            end
          records.each { |record| set_inverse_instance(record) }
          records
        end

      end

      private

      def foreign_shard_key
        options[:foreign_shard_key] || owner.turntable_shard_key
      end

      def should_use_shard_key?
        same_association_shard_key? || !!options[:foreign_shard_key]
      end

      def same_association_shard_key?
        owner.class.turntable_enabled? && klass.turntable_enabled? && foreign_shard_key == klass.turntable_shard_key
      end
    end
  end
end
