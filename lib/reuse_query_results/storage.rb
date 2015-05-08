module ReuseQueryResults
  module Storage
    class Base
      def add(table, sql, result)
        raise NotImplementedError
      end

      def fetch(table, sql)
        raise NotImplementedError
      end

      def clear(table)
        raise NotImplementedError
      end

      def fetch_or_execute(key, sql, &block)
        cached_result = fetch(key, sql)
        if cached_result
          Rails.logger.debug("HIT REUSE CACHE: #{sql}")
          return cached_result 
        end
        block.call.tap { |result| add(key, sql, result) }
      end

      def clear_and_execute(table, &block)
        clear(table)
        block.call
      end
    end

    class Memory < Base
      attr_reader :tables
      def initialize
        clear_all
      end

      def add(key, sql, result)
        @tables[key][sql] = result
      end

      def fetch(key, sql)
        @tables[key][sql]
      end

      def clear_all
        @tables = Hash.new { |k,v| k[v] = {} }
      end

      def clear(table)
        keys = @tables.keys.select { |key| (/##{key}(?:\z|\s)/) }
        keys.each do |key|
          @tables[key] = {}
        end
      end
    end
  end
end
