module ReuseQueryResults
  module Cache
    def execute(sql, *)
      ReuseQueryResults.cache(self, sql) do
        super
      end
    end

    def exec_query(sql, *)
      ReuseQueryResults.cache(self, sql) do
        super
      end
    end
  end
end

begin
  require 'active_record/connection_adapters/sqlite3_adapter'
  ::ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :prepend, ReuseQueryResults::Cache
rescue LoadError
end
begin
  require 'active_record/connection_adapters/postgresql_adapter'
  ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :prepend, ReuseQueryResults::Cache
rescue LoadError
end
begin
  require 'active_record/connection_adapters/abstract_mysql_adapter'
  ::ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.send :prepend, ReuseQueryResults::Cache
rescue LoadError
end
