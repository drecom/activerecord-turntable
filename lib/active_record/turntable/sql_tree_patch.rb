require 'sql_tree'
require 'active_support/core_ext/kernel/reporting'

module SQLTree
  class << self
    attr_accessor :identifier_quote_field_char
  end
  self.identifier_quote_field_char = '`'
end

class SQLTree::Token
  KEYWORDS << 'BINARY'
  KEYWORDS << 'LIMIT'
  KEYWORDS << 'OFFSET'
  const_set('BINARY', Class.new(SQLTree::Token::Keyword))
  const_set('LIMIT', Class.new(SQLTree::Token::Keyword))
  const_set('OFFSET', Class.new(SQLTree::Token::Keyword))
end

class SQLTree::Tokenizer
  def tokenize_quoted_string(&block) # :yields: SQLTree::Token::String
    string = ''
    until next_char.nil? || current_char == "'"
      string << (current_char == "\\" ? instance_eval("%@\\#{next_char.gsub('@', '\@')}@") : current_char)
    end
    handle_token(SQLTree::Token::String.new(string), &block)
  end
end

module SQLTree::Node
  class Base
    def quote_field_name(field_name)
      "#{SQLTree.identifier_quote_field_char}#{field_name}#{SQLTree.identifier_quote_field_char}"
    end
  end

  class SelectQuery < Base
    child :offset

    def to_sql(options = {})
      raise "At least one SELECT expression is required" if self.select.empty?
      sql = (self.distinct) ? "SELECT DISTINCT " : "SELECT "
      sql << select.map { |s| s.to_sql(options) }.join(', ')
      sql << " FROM "     << from.map { |f| f.to_sql(options) }.join(', ') if from
      sql << " WHERE "    << where.to_sql(options) if where
      sql << " GROUP BY " << group_by.map { |g| g.to_sql(options) }.join(', ') if group_by
      sql << " ORDER BY " << order_by.map { |o| o.to_sql(options) }.join(', ') if order_by
      sql << " HAVING "   << having.to_sql(options) if having
      sql << " LIMIT "    << Array(limit).map {|f| f.to_sql(options) }.join(', ') if limit
      sql << " OFFSET "   << offset.to_sql(options) if offset
      return sql
    end

    def self.parse(tokens)
      select_node = self.new
      tokens.consume(SQLTree::Token::SELECT)

      if SQLTree::Token::DISTINCT === tokens.peek
        tokens.consume(SQLTree::Token::DISTINCT)
        select_node.distinct = true
      end

      select_node.select   = parse_list(tokens, SQLTree::Node::SelectDeclaration)
      select_node.from     = self.parse_from_clause(tokens)   if SQLTree::Token::FROM === tokens.peek
      select_node.where    = self.parse_where_clause(tokens)  if SQLTree::Token::WHERE === tokens.peek
      if SQLTree::Token::GROUP === tokens.peek
        select_node.group_by = self.parse_group_clause(tokens)
        select_node.having   = self.parse_having_clause(tokens) if SQLTree::Token::HAVING === tokens.peek
      end
      select_node.order_by = self.parse_order_clause(tokens) if SQLTree::Token::ORDER === tokens.peek
      if SQLTree::Token::LIMIT === tokens.peek and list = self.parse_limit_clause(tokens)
        select_node.offset = list.shift if list.size > 1
        select_node.limit  = list.shift
      end
      select_node.offset = self.parse_offset_clause(tokens) if SQLTree::Token::OFFSET === tokens.peek
      return select_node
    end

    def self.parse_limit_clause(tokens)
      tokens.consume(SQLTree::Token::LIMIT)
      self.parse_list(tokens, SQLTree::Node::Expression)
    end

    def self.parse_offset_clause(tokens)
      tokens.consume(SQLTree::Token::OFFSET)
      Expression.parse(tokens)
    end
  end

  class SubQuery < SelectQuery
    def to_sql(options = {})
      "("+super(options)+")"
    end

    def self.parse(tokens)
      tokens.consume(SQLTree::Token::LPAREN)
      select_node = super(tokens)
      tokens.consume(SQLTree::Token::RPAREN)
      return select_node
    end
  end

  class TableReference < Base
    def to_sql(options={})
      sql = (SQLTree::Node::SubQuery === table) ? table.to_sql : quote_field_name(table)
      sql << " AS " << quote_field_name(table_alias) if table_alias
      return sql
    end

    def self.parse(tokens)
      if SQLTree::Token::Identifier === tokens.peek
        tokens.next
        table_reference = self.new(tokens.current.literal)
        if SQLTree::Token::AS === tokens.peek || SQLTree::Token::Identifier === tokens.peek
          tokens.consume(SQLTree::Token::AS) if SQLTree::Token::AS === tokens.peek
          table_reference.table_alias = tokens.next.literal
        end
        return table_reference
      elsif SQLTree::Token::SELECT === tokens.peek(2)
        table_reference = self.new(SQLTree::Node::SubQuery.parse(tokens))
        if SQLTree::Token::AS === tokens.peek || SQLTree::Token::Identifier === tokens.peek
          tokens.consume(SQLTree::Token::AS) if SQLTree::Token::AS === tokens.peek
          table_reference.table_alias = tokens.next.literal
        end
        table_reference
      else
        raise SQLTree::Parser::UnexpectedToken.new(tokens.current)
      end
    end
  end

  class Expression < Base
    class BinaryOperator < SQLTree::Node::Expression
      TOKEN_PRECEDENCE[2] << SQLTree::Token::BETWEEN
      silence_warnings do
        TOKENS = TOKEN_PRECEDENCE.flatten
      end

      def self.parse_rhs(tokens, precedence, operator = nil)
        if ['IN', 'NOT IN'].include?(operator)
          if SQLTree::Token::SELECT === tokens.peek(2)
            return SQLTree::Node::SubQuery.parse(tokens)
          else
            return List.parse(tokens)
          end
        elsif ['IS', 'IS NOT'].include?(operator)
          tokens.consume(SQLTree::Token::NULL)
          return SQLTree::Node::Expression::Value.new(nil)
        elsif ['BETWEEN'].include?(operator)
          expr = parse_atomic(tokens)
          operator = parse_operator(tokens)
          rhs      = parse_rhs(tokens, precedence, operator)
          expr     = self.new(:operator => operator, :lhs => expr, :rhs => rhs)
          return expr
        else
          return parse(tokens, precedence + 1)
        end
      end
    end

    class PrefixOperator < SQLTree::Node::Expression
      TOKENS << SQLTree::Token::BINARY
    end

    class Field < Variable
      def to_sql(options = {})
        @table.nil? ? quote_field_name(@name) : quote_field_name(@table) + '.' + quote_field_name(@name)
      end
    end
  end

  class InsertQuery < Base

    def to_sql(options = { })
      sql = "INSERT INTO #{ table.to_sql(options)} "
      sql << '(' + fields.map { |f| f.to_sql(options) }.join(', ') + ') ' if fields
      sql << 'VALUES'
      sql << values.map do |value|
               ' (' + value.map { |v| v.to_sql(options) }.join(', ') + ')'
             end.join(',')
      sql
    end

    def self.parse_value_list(tokens)
      values = []
      tokens.consume(SQLTree::Token::VALUES)
      tokens.consume(SQLTree::Token::LPAREN)
      values << parse_list(tokens)
      tokens.consume(SQLTree::Token::RPAREN)
      while SQLTree::Token::COMMA === tokens.peek
        tokens.consume(SQLTree::Token::COMMA)
        tokens.consume(SQLTree::Token::LPAREN)
        values << parse_list(tokens)
        tokens.consume(SQLTree::Token::RPAREN)
      end
      return values
    end
  end
end
