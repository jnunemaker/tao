# From project root:
# bundle exec ruby -Ilib examples/friends.rb
require_relative './_setup'

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
