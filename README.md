# Tao

Nothing to see here. Just playing around.

## Setup

### The Tables

```ruby
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
```

### The Code

```ruby
require 'tao'
client = Tao::Client.new
john = client.object.create("user").value!
steve = client.object.create("user").value!
hoyt = client.object.create("user").value!
brandon = client.object.create("user").value!
matt = client.object.create("user").value!

# make some friends
client.association.create(john.id, "friend", steve.id).value!
client.association.create(steve.id, "friend", john.id).value!
client.association.create(john.id, "friend", hoyt.id).value!
client.association.create(hoyt.id, "friend", john.id).value!
client.association.create(john.id, "friend", brandon.id).value!
client.association.create(brandon.id, "friend", john.id).value!
client.association.create(john.id, "friend", matt.id).value!
client.association.create(matt.id, "friend", john.id).value!

# count some friends
p client.association.count(john.id, "friend").value!  # => 4
p client.association.count(steve.id, "friend").value! # => 1

# query some friends
p client.association.range(john.id, "friend").value!
p client.association.range(john.id, "friend", offset: 3, limit: 10).value!
```

## Links

* https://www.facebook.com/notes/facebook-engineering/tao-the-power-of-the-graph/10151525983993920/
* https://www.usenix.org/conference/atc13/technical-sessions/presentation/bronson
* https://blog.acolyer.org/2015/05/19/tao-facebooks-distributed-data-store-for-the-social-graph/
