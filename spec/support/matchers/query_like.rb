RSpec::Matchers.define :query_like do |query_regexp|
  match do |actual|
    @expected = query_regexp
    capture_sql {
      actual.call
    }
    @sql_logs = SQLCounter.log
    @sql_logs.any? { |sql| @expected =~ sql }
  end

  def failure_message
    "\nexpected: #{@expected.inspect}\n  actual: #{@sql_logs.join("\n          ")}"
  end

  supports_block_expectations
end

RSpec::Matchers.define :have_queried do |count|
  match do |actual|
    @expected = count
    capture_sql {
      actual.call
    }
    @sql_size = SQLCounter.log.size
    @sql_size == count
  end

  def failure_message
    "\nexpected: #{@expected}\n  actual: #{@sql_size}"
  end

  supports_block_expectations
end
