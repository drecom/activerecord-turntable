require 'active_support/core_ext/object/try'
require 'active_record/turntable/sql_tree_patch'

module ActiveRecord::Turntable
  class Mixer
    extend ActiveSupport::Autoload

    eager_autoload do
      autoload :Fader
    end

    delegate :logger, :to => ActiveRecord::Base

    NOT_USED_FOR_SHARDING_OPERATORS_REGEXP = /\A(NOT IN|IS|IS NOT|BETWEEN|LIKE|\!\=|<<|>>|<>|>\=|<=|[\*\+\-\/\%\|\&><])\z/

    def initialize(proxy)
      @proxy = proxy
    end

    def build_fader(method_name, query, *args, &block)
      method = method_name.to_s
      if @proxy.shard_fixed?
        return SpecifiedShard.new(@proxy,
                                  { @proxy.fixed_shard => query },
                                  method, query, *args, &block)
      end
      binds = (method == 'insert') ? args[4] : args[1]
      binded_query = bind_sql(query, binds)

      begin
        tree = SQLTree[binded_query]
      rescue Exception => err
        logger.warn { "[ActiveRecord::Turntable] Error on Parsing SQL: #{binded_query}, on_method: #{method_name}" }
        raise err
      end

      case tree
      when SQLTree::Node::SelectQuery
        build_select_fader(tree, method, query, *args, &block)
      when SQLTree::Node::UpdateQuery, SQLTree::Node::DeleteQuery
        build_update_fader(tree, method, query, *args, &block)
      when SQLTree::Node::InsertQuery
        build_insert_fader(tree, method, query, *args, &block)
      else
        # send to master shard
        Fader::SpecifiedShard.new(@proxy,
                           { @proxy.master => query },
                           method, query, *args, &block)
      end
    rescue Exception => err
      logger.warn { "[ActiveRecord::Turntable] Error on Building Fader: #{binded_query}, on_method: #{method_name}" }
      raise err
    end

    def find_shard_keys(tree, table_name, shard_key)
      return [] unless tree.respond_to?(:operator)

      case tree.operator
      when "OR"
        lkeys = find_shard_keys(tree.lhs, table_name, shard_key)
        rkeys = find_shard_keys(tree.rhs, table_name, shard_key)
        if lkeys.present? and rkeys.present?
          lkeys + rkeys
        else
          []
        end
      when "AND"
        lkeys = find_shard_keys(tree.lhs, table_name, shard_key)
        rkeys = find_shard_keys(tree.rhs, table_name, shard_key)
        if lkeys.present? or rkeys.present?
          lkeys + rkeys
        else
          []
        end
      when "IN", "=", "=="
        field = tree.lhs.respond_to?(:table) ? tree.lhs : nil
        if tree.rhs.is_a?(SQLTree::Node::SubQuery)
          if field.try(:table) == table_name and field.name == shard_key
            find_shard_keys(tree.rhs.where, table_name, shard_key)
          else
            []
          end
        else
          values = Array(tree.rhs)
          if field.try(:table) == table_name and field.name == shard_key and
              !tree.rhs.is_a?(SQLTree::Node::SubQuery)
            values.map(&:value).compact
          else
            []
          end
        end
      when NOT_USED_FOR_SHARDING_OPERATORS_REGEXP
        []
      else
        raise ActiveRecord::Turntable::UnknownOperatorError,
          "[ActiveRecord::Turntable] Found Unknown SQL Operator:'#{tree.operator if tree.respond_to?(:operaor)}', Please report this bug."
      end
    end

    private

    def divide_insert_values(tree, shard_key_name)
      idx = tree.fields.find_index {|f| f.name == shard_key_name.to_s }
      result = {}
      tree.values.each do |val|
        (result[val[idx].value] ||= []) << val
      end
      return result
    end

    def build_shards_with_same_query(shards, query)
      Hash[shards.map {|s| [s, query] }]
    end

    def bind_sql(sql, binds)
      # TODO: substitution value should be determined by adapter
      query = sql.is_a?(String) ? sql : @proxy.to_sql(sql, binds ? binds.dup : [])
      query = if query.include?("\0") and binds.is_a?(Array) and binds[0].is_a?(Array) and binds[0][0].is_a?(ActiveRecord::ConnectionAdapters::Column)
                binds = binds.dup
                query.gsub("\0") { @proxy.master.connection.quote(*binds.shift.reverse) }
              else
                query
              end
    end

    def build_select_fader(tree, method, query, *args, &block)
      shard_keys = if !tree.where and tree.from.size == 1 and SQLTree::Node::SubQuery === tree.from.first.table_reference.table
                     find_shard_keys(tree.from.first.table_reference.table.where,
                                     @proxy.cluster.klass.table_name,
                                     @proxy.cluster.klass.turntable_shard_key.to_s)
                   else
                     find_shard_keys(tree.where,
                                     @proxy.cluster.klass.table_name,
                                     @proxy.cluster.klass.turntable_shard_key.to_s)
                   end

      if shard_keys.size == 1 # shard
        return Fader::SpecifiedShard.new(@proxy,
                                         { @proxy.cluster.shard_for(shard_keys.first) => query },
                                         method, query, *args, &block)
      elsif SQLTree::Node::SelectDeclaration === tree.select.first and
              tree.select.first.to_sql == '1 AS "one"'  # for `SELECT 1 AS one` (AR::Base.exists?)
        return Fader::SelectShardsMergeResult.new(@proxy,
                                                  build_shards_with_same_query(@proxy.shards.values, query),
                                                  method, query, *args, &block
                                                  )
      elsif tree.group_by or tree.order_by or tree.limit.try(:value).to_i > 0
        raise CannotSpecifyShardError, "cannot specify shard for query: #{tree.to_sql}"
      elsif shard_keys.present?
        if SQLTree::Node::SelectDeclaration === tree.select.first and
            SQLTree::Node::CountAggregrate === tree.select.first.expression
          return Fader::CalculateShardsSumResult.new(@proxy,
                                                     build_shards_with_same_query(@proxy.shards.values, query),
                                                     method, query, *args, &block)
        else
          return Fader::SelectShardsMergeResult.new(@proxy,
                                                    Hash[shard_keys.map {|k| [@proxy.cluster.shard_for(k), query] }],
                                                    method, query, *args, &block
                                                    )
        end
      else # scan all shards
        if SQLTree::Node::SelectDeclaration === tree.select.first and
            SQLTree::Node::CountAggregrate === tree.select.first.expression

          if raise_on_not_specified_shard_query?
            raise CannotSpecifyShardError, "[Performance Notice] PLEASE FIX: #{tree.to_sql}"
          end
          return Fader::CalculateShardsSumResult.new(@proxy,
                                                     build_shards_with_same_query(@proxy.shards.values, query),
                                                     method, query, *args, &block)
        elsif SQLTree::Node::AllFieldsDeclaration === tree.select.first or
            SQLTree::Node::Expression::Value === tree.select.first.expression or
            SQLTree::Node::Expression::Variable === tree.select.first.expression

          if raise_on_not_specified_shard_query?
            raise CannotSpecifyShardError, "[Performance Notice] PLEASE FIX: #{tree.to_sql}"
          end
          return Fader::SelectShardsMergeResult.new(@proxy,
                                                    build_shards_with_same_query(@proxy.shards.values, query),
                                                    method, query, *args, &block
                                                    )
        else
          raise CannotSpecifyShardError, "cannot specify shard for query: #{tree.to_sql}"
        end
      end
    end

    def build_update_fader(tree, method, query, *args, &block)
      shard_keys = find_shard_keys(tree.where, @proxy.cluster.klass.table_name, @proxy.cluster.klass.turntable_shard_key.to_s)
      shards_with_query = if shard_keys.present?
                            build_shards_with_same_query(shard_keys.map {|k| @proxy.cluster.shard_for(k) }, query)
                          else
                            build_shards_with_same_query(@proxy.shards.values, query)
                          end

      if shards_with_query.size == 1
        Fader::SpecifiedShard.new(@proxy,
                                  shards_with_query,
                                  method, query, *args, &block)
      else
        if raise_on_not_specified_shard_update?
          raise CannotSpecifyShardError, "[Performance Notice] PLEASE FIX: #{tree.to_sql}"
        end
        Fader::UpdateShardsMergeResult.new(@proxy,
                                           shards_with_query,
                                           method, query, *args, &block)
      end
    end

    def build_insert_fader(tree, method, query, *args, &block)
      values_hash = divide_insert_values(tree, @proxy.cluster.klass.turntable_shard_key)
      shards_with_query = {}
      values_hash.each do |k,vs|
        tree.values = [[SQLTree::Node::Expression::Variable.new("\\0")]]
        sql = tree.to_sql
        value_sql = vs.map do |val|
          "(#{val.map { |v| @proxy.connection.quote(v.value)}.join(', ')})"
        end.join(', ')
        sql.gsub!('("\0")') { value_sql }
        shards_with_query[@proxy.cluster.shard_for(k)] = sql
      end
      Fader::InsertShardsMergeResult.new(@proxy, shards_with_query, method, query, *args, &block)
    end

    def raise_on_not_specified_shard_query?
      ActiveRecord::Base.turntable_config[:raise_on_not_specified_shard_query]
    end

    def raise_on_not_specified_shard_update?
      ActiveRecord::Base.turntable_config[:raise_on_not_specified_shard_update]
    end
  end
end
