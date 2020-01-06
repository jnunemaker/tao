require "github/sql"
require "github/result"
require "tao/object"

module Tao
  module Adapters
    module Postgres
      class Objects
        def initialize(serializer:)
          @serializer = serializer
        end

        def get(id)
          GitHub::Result.new do
            binds = {
              id: id,
              force_timezone: :utc,
            }
            sql = GitHub::SQL.run <<-SQL, binds
              SELECT type, id, value FROM tao_objects WHERE id = :id LIMIT 1
            SQL

            if row = sql.results[0]
              type, id, value = row
              data = @serializer.load(value)
              Object.new(type, id, data)
            else
              nil
            end
          end
        end

        def create(type, data = {})
          GitHub::Result.new do
            binds = {
              type: type,
              value: @serializer.dump(data),
              force_timezone: :utc,
            }
            sql = GitHub::SQL.run <<-SQL, binds
              INSERT INTO tao_objects (type, value) VALUES (:type, :value)
            SQL
            Object.new(type, sql.last_insert_id)
          end
        end

        def update(id, data = {})
          GitHub::Result.new do
            binds = {
              id: id,
              force_timezone: :utc,
            }
            sql = GitHub::SQL.run <<-SQL, binds
              SELECT type, value FROM tao_objects WHERE id = :id LIMIT 1
            SQL
            type = nil
            existing_data = if (row = sql.results[0])
              type, value = row
              @serializer.load(value)
            else
              {}
            end

            value = @serializer.dump(existing_data.merge(data))
            binds = {
              id: id,
              value: value,
              force_timezone: :utc,
            }
            sql = GitHub::SQL.run <<-SQL, binds
              UPDATE tao_objects SET value = :value WHERE id = :id
            SQL

            new_data = @serializer.load(value)
            Object.new(type, id, new_data)
          end
        end

        def delete(id)
          GitHub::Result.new do
            binds = {
              id: id,
              force_timezone: :utc,
            }
            sql = GitHub::SQL.run <<-SQL, binds
              DELETE FROM tao_objects WHERE id = :id
            SQL
            sql.affected_rows > 0
          end
        end
      end
    end
  end
end
