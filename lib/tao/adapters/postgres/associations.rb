require "github/sql"
require "github/result"
require "tao/association"

module Tao
  module Adapters
    module Postgres
      class Associations
        DEFAULT_LIMIT = 6_000

        def initialize(serializer:)
          @serializer = serializer
        end

        def get(id1, type, id2_set, high: nil, low: nil)
          GitHub::Result.new do
            binds = {
              id1: id1,
              type: type,
              id2_set: id2_set,
              force_timezone: :utc,
            }
            sql = GitHub::SQL.new <<-SQL, binds
              SELECT id1, type, id2, created_at, value FROM tao_associations
              WHERE id1 = :id1 AND type = :type AND id2 IN :id2_set
            SQL

            if high
              sql.add "AND created_at <= :high", high: high.utc
            end

            if low
              sql.add "AND created_at >= :low", low: low.utc
            end

            sql.results.map do |row|
              id1, type, id2, created_at, value = row
              Association.new(id1, type, id2, Time.parse(created_at + " UTC"), value)
            end
          end
        end

        def range(id1, type, offset: 0, limit: DEFAULT_LIMIT)
          GitHub::Result.new do
            binds = {
              id1: id1,
              type: type,
              offset: offset,
              limit: limit,
              force_timezone: :utc,
            }
            sql = GitHub::SQL.new <<-SQL, binds
              SELECT id1, type, id2, created_at, value FROM tao_associations
              WHERE id1 = :id1 AND type = :type
              ORDER BY created_at DESC
              LIMIT :limit
              OFFSET :offset
            SQL
            sql.results.map do |row|
              id1, type, id2, created_at, value = row
              Association.new(id1, type, id2, Time.parse(created_at + " UTC"), value)
            end
          end
        end

        def time_range(id1, type, high:, low:, limit: DEFAULT_LIMIT)
          GitHub::Result.new do
            binds = {
              id1: id1,
              type: type,
              high: high.utc,
              low: low.utc,
              limit: limit,
              force_timezone: :utc,
            }
            sql = GitHub::SQL.new <<-SQL, binds
              SELECT id1, type, id2, created_at, value FROM tao_associations
              WHERE
                id1 = :id1 AND
                type = :type AND
                created_at >= :low AND
                created_at <= :high
              ORDER BY
                created_at DESC
              LIMIT :limit
            SQL
            sql.results.map do |row|
              id1, type, id2, created_at, value = row
              Association.new(id1, type, id2, Time.parse(created_at + " UTC"), value)
            end
          end
        end

        def count(id1, type)
          GitHub::Result.new do
            binds = {
              id1: id1,
              type: type,
              force_timezone: :utc,
            }
            GitHub::SQL.value <<-SQL, binds
              SELECT count(*) FROM tao_associations
              WHERE id1 = :id1 AND type = :type
            SQL
          end
        end

        def create(id1, type, id2, time = Time.now.utc, data = {})
          GitHub::Result.new do
            binds = {
              id1: id1,
              type: type,
              id2: id2,
              created_at: time.utc,
              value: @serializer.dump(data),
              force_timezone: :utc,
            }
            sql = GitHub::SQL.run <<-SQL, binds
              INSERT INTO tao_associations (id1, type, id2, created_at, value)
              VALUES (:id1, :type, :id2, :created_at, :value)
            SQL
            Association.new(id1, type, id2, time.utc, data)
          end
        end

        def delete(id1, type, id2)
          GitHub::Result.new do
            binds = {
              id1: id1,
              type: type,
              id2: id2,
              force_timezone: :utc,
            }
            sql = GitHub::SQL.run <<-SQL, binds
              DELETE FROM tao_associations
              WHERE id1 = :id1 AND type = :type AND id2 = :id2
            SQL
            sql.affected_rows > 0
          end
        end

        def change_type(id1, type, id2, new_type)
          GitHub::Result.new do
            binds = {
              id1: id1,
              type: type,
              id2: id2,
              new_type: new_type,
              force_timezone: :utc,
            }
            sql = GitHub::SQL.run <<-SQL, binds
              UPDATE tao_associations
              SET type = :new_type
              WHERE id1 = :id1 AND type = :type AND id2 = :id2
            SQL
            sql.affected_rows > 0
          end
        end
      end
    end
  end
end
