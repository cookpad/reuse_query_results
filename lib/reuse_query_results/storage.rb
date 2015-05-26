module ReuseQueryResults
  module Storage
    class Base
      def add(database, table, sql, result)
        raise NotImplementedError
      end

      def fetch(database, table, sql)
        raise NotImplementedError
      end

      def clear(database, table)
        raise NotImplementedError
      end

      def fetch_or_execute(database, key, sql, &block)
        cached_result = fetch(database, key, sql)
        if cached_result
          Rails.logger.debug("HIT REUSE CACHE: #{sql}")
          return cached_result
        end
        block.call.tap { |result| add(database, key, sql, result) }
      end

      def clear_and_execute(database, table, &block)
        clear(database, table)
        block.call
      end
    end

    class Memory < Base
      attr_reader :databases
      def initialize
        clear_all
      end

      def add(database, key, sql, result)
        @databases[database][key][sql] = result
      end

      def fetch(database, key, sql)
        @databases[database][key][sql]
      end

      def clear_all
        @databases = Hash.new do |h, k| 
          h[k] = Hash.new { |h2, k2| h2[k2] = {} }
        end
      end

      def clear(database, table)
        keys = @databases[database].keys.select { |key| (/##{key}(?:\z|\s)/) }
        keys.each do |key|
          @databases[database][key] = {}
        end
      end
    end
  end
end
