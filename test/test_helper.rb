$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tao'
require 'minitest/autorun'

ActiveRecord::Base.establish_connection({
  adapter: "postgresql",
  database: "tao_test",
})
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS tao_objects")
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS tao_associations")
ActiveRecord::Base.connection.execute(<<-SQL)
  CREATE TABLE tao_objects (
    id BIGSERIAL NOT NULL,
    type CHARACTER VARYING(255) NOT NULL,
    value JSONB NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (id)
  )
SQL
ActiveRecord::Base.connection.execute(<<-SQL)
  CREATE TABLE tao_associations (
    id1 BIGINT NOT NULL,
    type CHARACTER VARYING(255) NOT NULL,
    id2 BIGINT NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    value JSONB NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (id1, type, id2)
  )
SQL
ActiveRecord::Base.connection.execute(<<-SQL)
  CREATE INDEX index_tao_associations_on_time ON tao_associations(id1, type, created_at)
SQL
