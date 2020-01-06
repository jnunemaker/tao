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
[steve, hoyt, brandon, matt].each do |user|
  client.associations.create(john.id, "friend", user.id).value!
  client.associations.create(user.id, "friend", john.id).value!
end

# count some friends
p client.associations.count(john.id, "friend").value!  # => 4
p client.associations.count(steve.id, "friend").value! # => 1

# query some friends
p client.associations.range(john.id, "friend").value!
p client.associations.range(john.id, "friend", offset: 3, limit: 10).value!
