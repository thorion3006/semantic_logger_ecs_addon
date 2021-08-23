# frozen_string_literal: true

require "sequel/database/logging"
# require "active_support/notifications"

module Sequel
  class Database
    def log_connection_yield sql, conn, args = nil
      log_connection_info = (connection_info conn if conn && log_connection_info)
      log_args = ("; #{args.inspect}" if args)
      sql_for_log = "#{log_connection_info}#{sql}#{log_args}"
      start = Time.now
      begin
        ::ActiveSupport::Notifications.instrument(
          "sql.sequel",
          sql: sql,
          name: self.class,
          binds: args
        ) do
          yield
        end
      rescue StandardError => error
        log_exception error, sql_for_log unless @loggers.empty?
        raise
      ensure
        log_duration Time.now - start, sql_for_log unless error || @loggers.empty?
      end
    end

    def log_yield sql, args = nil, &block
      log_connection_yield(sql, nil, args, &block)
    end
  end
end
