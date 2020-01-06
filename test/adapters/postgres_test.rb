require 'test_helper'

class PostgresAdapterTest < Minitest::Test
  def setup
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE tao_objects")
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE tao_associations")
  end

  def test_paper_example_works
    client = Tao::Client.new

    # create users
    bob = client.object.create("user", name: "Bob").value!
    alice = client.object.create("user", name: "Alice").value!
    david = client.object.create("user", name: "David").value!
    cathy = client.object.create("user", name: "Cathy").value!

    # create friendships
    [bob, david, cathy].each do |user|
      client.association.create(alice.id, "friend", user.id).value!
      client.association.create(user.id, "friend", alice.id).value!
    end

    # create checkin
    checkin = client.object.create("checkin").value!
    client.association.create(alice.id, "authored", checkin.id).value!
    client.association.create(checkin.id, "authored_by", alice.id).value!

    # create location
    location = client.object.create("location", name: "Golden Gate Bridge").value!
    assert_equal "Golden Gate Bridge", client.object.get(location.id).value!.data.fetch("name")
    client.association.create(checkin.id, "location", location.id).value!
    client.association.create(location.id, "checkin", checkin.id).value!

    # tag bob at checkin
    client.association.create(checkin.id, "tagged", bob.id).value!
    client.association.create(bob.id, "tagged_at", checkin.id).value!

    # create comment for cathy on checkin
    comment = client.object.create("comment", text: "Wish we were there!").value!
    client.association.create(comment.id, "authored_by", cathy.id).value!
    client.association.create(cathy.id, "authored", comment.id).value!

    # david likes cathy's comment
    client.association.create(comment.id, "liked_by", david.id).value!
    client.association.create(david.id, "likes", comment.id).value!

    # get alice's friends
    friends = client.association.range(alice.id, "friend").value!
    assert_equal 3, friends.size
    assert_equal [cathy.id, david.id, bob.id].sort, friends.map(&:id2).sort

    # bob's friend
    assert_equal [alice.id], client.association.range(bob.id, "friend").value!.map(&:id2)
  end
end
