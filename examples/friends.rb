# From project root:
# bundle exec ruby -Ilib examples/friends.rb
require_relative './_setup'

client = Tao::Client.new
john = client.objects.create("user").value!
steve = client.objects.create("user").value!
hoyt = client.objects.create("user").value!
brandon = client.objects.create("user").value!
matt = client.objects.create("user").value!

# make some friends
client.associations.create(john.id, "friend", steve.id).value!
client.associations.create(steve.id, "friend", john.id).value!
client.associations.create(john.id, "friend", hoyt.id).value!
client.associations.create(hoyt.id, "friend", john.id).value!
client.associations.create(john.id, "friend", brandon.id).value!
client.associations.create(brandon.id, "friend", john.id).value!
client.associations.create(john.id, "friend", matt.id).value!
client.associations.create(matt.id, "friend", john.id).value!

# count some friends
p client.associations.count(john.id, "friend").value!  # => 4
p client.associations.count(steve.id, "friend").value! # => 1

# query some friends
p client.associations.range(john.id, "friend").value!
p client.associations.range(john.id, "friend", offset: 3, limit: 10).value!
