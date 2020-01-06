require 'test_helper'

class PostgresAdapterTest < Minitest::Test
  def setup
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE tao_objects")
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE tao_associations")
  end

  def test_paper_example_works
    client = Tao::Client.new

    # create users
    bob = client.objects.create("user", name: "Bob").value!
    alice = client.objects.create("user", name: "Alice").value!
    david = client.objects.create("user", name: "David").value!
    cathy = client.objects.create("user", name: "Cathy").value!

    # create friendships
    [bob, david, cathy].each do |user|
      client.associations.create(alice.id, "friend", user.id).value!
      client.associations.create(user.id, "friend", alice.id).value!
    end

    # create checkin
    checkin = client.objects.create("checkin").value!
    client.associations.create(alice.id, "authored", checkin.id).value!
    client.associations.create(checkin.id, "authored_by", alice.id).value!

    # create location
    location = client.objects.create("location", name: "Golden Gate Bridge").value!
    assert_equal "Golden Gate Bridge", client.objects.get(location.id).value!.data.fetch("name")
    client.associations.create(checkin.id, "location", location.id).value!
    client.associations.create(location.id, "checkin", checkin.id).value!

    # tag bob at checkin
    client.associations.create(checkin.id, "tagged", bob.id).value!
    client.associations.create(bob.id, "tagged_at", checkin.id).value!

    # create comment for cathy on checkin
    comment = client.objects.create("comment", text: "Wish we were there!").value!
    client.associations.create(comment.id, "authored_by", cathy.id).value!
    client.associations.create(cathy.id, "authored", comment.id).value!

    # david likes cathy's comment
    client.associations.create(comment.id, "liked_by", david.id).value!
    client.associations.create(david.id, "likes", comment.id).value!

    # get alice's friends
    friends = client.associations.range(alice.id, "friend").value!
    assert_equal 3, friends.size
    assert_equal [cathy.id, david.id, bob.id].sort, friends.map(&:id2).sort

    # bob's friend
    assert_equal [alice.id], client.associations.range(bob.id, "friend").value!.map(&:id2)
  end
end
