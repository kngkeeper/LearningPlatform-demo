require "test_helper"

class DatabaseConnectionTest < ActionDispatch::IntegrationTest
  test "can connect to database" do
    # Test basic database connectivity
    assert ActiveRecord::Base.connection.active?

    # Test we can execute a simple query
    result = ActiveRecord::Base.connection.execute("SELECT 1 as test_value")
    # Handle different result formats from MySQL adapter
    first_row = result.first
    test_value = first_row.is_a?(Hash) ? first_row["test_value"] : first_row[0]
    assert_equal 1, test_value
  end

  test "database configuration is correct for CI environment" do
    config = ActiveRecord::Base.connection_db_config.configuration_hash

    if ENV["GITHUB_ACTIONS"]
      assert_equal "127.0.0.1", config[:host]
      assert_equal 3306, config[:port]
      assert_nil config[:socket]
    else
      assert_equal "/var/run/mysqld/mysqld.sock", config[:socket]
    end

    assert_equal "learning_platform", config[:username]
    assert_equal "mysql2", config[:adapter]
    assert_equal "utf8mb4", config[:encoding]
  end
end
