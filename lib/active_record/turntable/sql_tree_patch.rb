# rubocop:disable Style/CaseEquality
require "sql_tree"
require "active_support/core_ext/kernel/reporting"

module SQLTree
  class << self
    attr_accessor :identifier_quote_field_char
  end
  self.identifier_quote_field_char = "`"

  COMMENT_PATTERN = %r{\/\*[\s\S]*?\*\/}.freeze
  def self.[](query, options = {})
    sql = query.kind_of?(String) ? query.gsub(COMMENT_PATTERN, "") : query
    SQLTree::Parser.parse(sql)
  end
end

class SQLTree::Token
  extended_keywords = %w(BINARY LIMIT OFFSET INDEX KEY USE FORCE IGNORE TRUE FALSE)
  KEYWORDS.concat(extended_keywords)

  extended_keywords.each do |kwd|
    const_set(kwd, Class.new(SQLTree::Token::Keyword))
  end

  BINARY_ESCAPE = Class.new(SQLTree::Token).new("x")

  def possible_index_hint?
    [SQLTree::Token::USE, SQLTree::Token::FORCE, SQLTree::Token::IGNORE].include?(self.class)
  end

  def index_keyword?
    [SQLTree::Token::INDEX, SQLTree::Token::KEY].include?(self.class)
  end
end

class SQLTree::Tokenizer
  def tokenize_quoted_string(&block) # :yields: SQLTree::Token::String
    string = ""
    until next_char.nil? || current_char == "'"
      string << (current_char == "\\" ? instance_eval("%@\\#{next_char.gsub('@', '\@')}@") : current_char)
    end
    handle_token(SQLTree::Token::String.new(string), &block)
  end

  # @note Override to handle x'..' binary string
  # rubocop:disable Lint/EmptyWhen:
  def each_token(&block) # :yields: SQLTree::Token
    while next_char
      case current_char
      when /^\s?$/ then # whitespace, go to next character
      when "(" then            handle_token(SQLTree::Token::LPAREN, &block)
      when ")" then            handle_token(SQLTree::Token::RPAREN, &block)
      when "." then            handle_token(SQLTree::Token::DOT, &block)
      when "," then            handle_token(SQLTree::Token::COMMA, &block)
      when /\d/ then           tokenize_number(&block)
      when "'" then            tokenize_quoted_string(&block)
      when "E", "x", "X" then  tokenize_possible_escaped_string(&block)
      when /\w/ then           tokenize_keyword(&block)
      when OPERATOR_CHARS then tokenize_operator(&block)
      when SQLTree.identifier_quote_char then tokenize_quoted_identifier(&block)
      end
    end

    # Make sure to yield any tokens that are still stashed on the queue.
    empty_keyword_queue!(&block)
  end
  # rubocop:enable Lint/EmptyWhen:
  alias_method :each, :each_token

  def tokenize_possible_escaped_string(&block)
    if peek_char == "'"
      token = case current_char
              when "E"
                SQLTree::Token::STRING_ESCAPE
              when "x", "X"
                SQLTree::Token::BINARY_ESCAPE
              end
      handle_token(token, &block)
    else
      tokenize_keyword(&block)
    end
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
      sql = self.distinct ? "SELECT DISTINCT " : "SELECT "
      sql << select.map { |s| s.to_sql(options) }.join(", ")
      sql << " FROM "     << from.map { |f| f.to_sql(options) }.join(", ") if from
      sql << " WHERE "    << where.to_sql(options) if where
      sql << " GROUP BY " << group_by.map { |g| g.to_sql(options) }.join(", ") if group_by
      sql << " ORDER BY " << order_by.map { |o| o.to_sql(options) }.join(", ") if order_by
      sql << " HAVING "   << having.to_sql(options) if having
      sql << " LIMIT "    << Array(limit).map { |f| f.to_sql(options) }.join(", ") if limit
      sql << " OFFSET "   << offset.to_sql(options) if offset
      sql
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
      if SQLTree::Token::LIMIT === tokens.peek && (list = self.parse_limit_clause(tokens))
        select_node.offset = list.shift if list.size > 1
        select_node.limit  = list.shift
      end
      select_node.offset = self.parse_offset_clause(tokens) if SQLTree::Token::OFFSET === tokens.peek
      select_node
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
      "(" + super(options) + ")"
    end

    def self.parse(tokens)
      tokens.consume(SQLTree::Token::LPAREN)
      select_node = super(tokens)
      tokens.consume(SQLTree::Token::RPAREN)
      select_node
    end
  end

  class TableReference < Base
    leaf :index_hint

    def initialize(table, table_alias = nil, index_hint = nil)
      @table = table
      @table_alias = table_alias
      @index_hint = index_hint
    end

    def to_sql(options = {})
      sql = (SQLTree::Node::SubQuery === table) ? table.to_sql : quote_field_name(table)
      sql << " AS " << quote_field_name(table_alias) if table_alias
      sql << " " << index_hint.to_sql if index_hint
      sql
    end

    def self.parse(tokens)
      if SQLTree::Token::Identifier === tokens.peek
        tokens.next
        table_reference = self.new(tokens.current.literal)
        if tokens.peek && !tokens.peek.possible_index_hint? &&
           (SQLTree::Token::AS === tokens.peek || SQLTree::Token::Identifier === tokens.peek)
          tokens.consume(SQLTree::Token::AS) if SQLTree::Token::AS === tokens.peek
          table_reference.table_alias = tokens.next.literal
        end
        if tokens.peek && tokens.peek.possible_index_hint? && tokens.peek(2).index_keyword?
          table_reference.index_hint = SQLTree::Node::IndexHint.parse(tokens)
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
        raise SQLTree::Parser::UnexpectedToken, tokens.current
      end
    end
  end

  class IndexHint < Base
    leaf :hint_method
    leaf :hint_key
    leaf :index_list

    def initialize(hint_method, hint_key, index_list)
      @hint_method = hint_method
      @hint_key = hint_key
      @index_list = index_list
    end

    def to_sql(options = {})
      sql = "#{hint_method} #{hint_key} "
      sql << "(#{index_list.map(&:to_sql).join(' ')})"
      sql
    end

    def self.parse(tokens)
      hint_method = tokens.next.literal
      if tokens.peek.index_keyword?
        hint_key = tokens.next.literal
        tokens.consume(SQLTree::Token::LPAREN)
        index_list = parse_list(tokens, SQLTree::Node::Expression::Field)
        tokens.consume(SQLTree::Token::RPAREN)
        self.new(hint_method, hint_key, index_list)
      else
        raise SQLTree::Parser::UnexpectedToken, tokens.current
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
        if ["IN", "NOT IN"].include?(operator)
          if SQLTree::Token::SELECT === tokens.peek(2)
            return SQLTree::Node::SubQuery.parse(tokens)
          else
            return List.parse(tokens)
          end
        elsif ["IS", "IS NOT"].include?(operator)
          tokens.consume(SQLTree::Token::NULL)
          return SQLTree::Node::Expression::Value.new(nil)
        elsif ["BETWEEN"].include?(operator)
          expr = parse_atomic(tokens)
          operator = parse_operator(tokens)
          rhs      = parse_rhs(tokens, precedence, operator)
          expr     = self.new(operator: operator, lhs: expr, rhs: rhs)
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
        @table.nil? ? quote_field_name(@name) : quote_field_name(@table) + "." + quote_field_name(@name)
      end
    end

    class Value
      leaf :escape

      def to_sql(options = {})
        case value
        when nil;            'NULL'
        when true;           'TRUE'
        when false;          'FALSE'
        when String;         quote_str(@value)
        when Numeric;        @value.to_s
        when Date;           @value.strftime("'%Y-%m-%d'")
        when DateTime, Time; @value.strftime("'%Y-%m-%d %H:%M:%S'")
        else raise "Don't know how te represent this value in SQL!"
        end
      end

      def self.parse(tokens)
        case tokens.next
        when SQLTree::Token::String, SQLTree::Token::Number
          SQLTree::Node::Expression::Value.new(tokens.current.literal)
        when SQLTree::Token::NULL
          SQLTree::Node::Expression::Value.new(nil)
        when SQLTree::Token::TRUE
          SQLTree::Node::Expression::Value.new(true)
        when SQLTree::Token::FALSE
          SQLTree::Node::Expression::Value.new(false)
        else
          raise SQLTree::Parser::UnexpectedToken.new(tokens.current, :literal)
        end
      end
    end

    class EscapedValue < Value
      def initialize(value, escape = nil)
        @value = value
        @escape = escape
      end

      def to_sql(options = {})
        case value
        when nil then            "NULL"
        when String then         "#{escape_string}#{quote_str(@value)}"
        when Numeric then        @value.to_s
        when Date then           @value.strftime("'%Y-%m-%d'")
        when DateTime, Time then @value.strftime("'%Y-%m-%d %H:%M:%S'")
        else raise "Don't know how te represent this value in SQL!"
        end
      end

      def escape_string
        @escape.to_s
      end

      def self.parse(tokens)
        escape = tokens.next
        case tokens.next
        when SQLTree::Token::String
          SQLTree::Node::Expression::EscapedValue.new(tokens.current.literal, escape.literal)
        else
          raise SQLTree::Parser::UnexpectedToken.new(tokens.current, :literal)
        end
      end
    end

    def self.parse_atomic(tokens)
      if SQLTree::Token::LPAREN === tokens.peek
        tokens.consume(SQLTree::Token::LPAREN)
        expr = self.parse(tokens)
        tokens.consume(SQLTree::Token::RPAREN)
        expr
      elsif tokens.peek.prefix_operator?
        PrefixOperator.parse(tokens)
      elsif tokens.peek.variable?
        if SQLTree::Token::LPAREN === tokens.peek(2)
          FunctionCall.parse(tokens)
        elsif SQLTree::Token::DOT === tokens.peek(2)
          Field.parse(tokens)
        else
          Variable.parse(tokens)
        end
      elsif SQLTree::Token::STRING_ESCAPE == tokens.peek
        EscapedValue.parse(tokens)
      elsif SQLTree::Token::BINARY_ESCAPE == tokens.peek
        EscapedValue.parse(tokens)
      elsif SQLTree::Token::INTERVAL === tokens.peek
        IntervalValue.parse(tokens)
      else
        Value.parse(tokens)
      end
    end
  end

  class InsertQuery < Base
    def to_sql(options = {})
      sql = "INSERT INTO #{table.to_sql(options)} "
      sql << "(" + fields.map { |f| f.to_sql(options) }.join(", ") + ") " if fields
      sql << "VALUES"
      sql << values.map do |value|
        " (" + value.map { |v| v.to_sql(options) }.join(", ") + ")"
      end.join(",")
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
      values
    end
  end
end
# rubocop:enable Style/CaseEquality
