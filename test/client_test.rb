require 'test_helper'

FRIEND = "FRIEND"

class TaoClientTest < Minitest::Test
  def setup
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE `tao_objects`")
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE `tao_associations`")
  end

  def test_can_create_read_update_and_delete_objects
    client = Tao::Client.new
    object = client.object.create("user").value!
    assert_instance_of Tao::Object, object
    assert_equal "user", object.type
    assert object.id > 0, "#{object.id} expected to be greater than 0, but was not"
    assert_equal 1, objects_count

    read_object = client.object.get(object.id).value!
    assert_instance_of Tao::Object, object
    assert_equal "user", read_object.type
    assert_equal object.id, read_object.id

    updated_object = client.object.update(object.id, foo: "bar").value!
    assert_instance_of Tao::Object, object
    assert_equal "user", updated_object.type
    assert_equal object.id, updated_object.id
    assert_equal "bar", updated_object.data["foo"]

    client.object.delete(object.id)
    assert_nil client.object.get(object.id).value!
  end

  def test_can_create_get_change_type_and_delete_association
    client = Tao::Client.new

    o1 = client.object.create("user").value!
    o2 = client.object.create("user").value!
    association = client.association.create(o1.id, "friend", o2.id).value!
    assert_instance_of Tao::Association, association
    assert_equal 1, associations_count
    now = Time.now.utc

    friend_associations = client.association.get(o1.id, "friend", [o2.id]).value!
    assert_instance_of Array, friend_associations
    friend_association = friend_associations.first
    assert_instance_of Tao::Association, friend_association
    assert_equal o1.id, friend_association.id1
    assert_equal "friend", friend_association.type
    assert_equal o2.id, friend_association.id2
    assert_in_delta now, friend_association.time, 2

    result = client.association.change_type(o1.id, "friend", o2.id, "enemy").value!
    assert result
    assert_equal 1, associations_count

    enemy_associations = client.association.get(o1.id, "enemy", [o2.id]).value!
    assert_instance_of Array, enemy_associations
    enemy_association = enemy_associations.first
    assert_instance_of Tao::Association, enemy_association
    assert_equal o1.id, enemy_association.id1
    assert_equal "enemy", enemy_association.type
    assert_equal o2.id, enemy_association.id2
    assert_in_delta now, enemy_association.time, 2

    assert client.association.delete(o1.id, "enemy", o2.id).value!
  end

  def test_can_create_association_with_time_and_data
    client = Tao::Client.new

    o1 = client.object.create("user").value!
    o2 = client.object.create("user").value!
    time = Time.now.utc - 60
    data = {"foo" => "bar"}
    association = client.association.create(o1.id, "friend", o2.id, time, data).value!
    assert_instance_of Tao::Association, association
    assert_equal 1, associations_count
    assert_equal time, association.time
    assert_equal data, association.data
  end

  def test_assocation_querying
    day = 60 * 60 * 24
    now = Time.now.utc
    client = Tao::Client.new

    user = client.object.create("user").value!
    friends = []

    (1..100).each do |n|
      friend = client.object.create("user").value!
      friends << friend
      time = now - (n * day)
      client.association.create(user.id, "friend", friend.id, time).value!
    end

    assert_equal 100, client.association.count(user.id, "friend").value!

    friend_ids = friends[11..20].map(&:id)
    associations = client.association.get(user.id, "friend", friend_ids).value!
    assert_equal 10, associations.size
    associations.each do |association|
      assert_equal user.id, association.id1
      assert_equal "friend", association.type
      assert_includes friend_ids, association.id2
    end

    friend_ids = friends.map(&:id)
    associations = client.association.get(user.id, "friend", friend_ids, high: now - (5 * day)).value!
    assert_equal 96, associations.size

    friend_ids = friends.map(&:id)
    associations = client.association.get(user.id, "friend", friend_ids, low: now - (5 * day)).value!
    assert_equal 5, associations.size

    associations = client.association.range(user.id, "friend", offset: 10).value!
    assert_equal 90, associations.size

    associations = client.association.range(user.id, "friend", offset: 10, limit: 10).value!
    assert_equal 10, associations.size
    assert_equal friends[10..19].map(&:id), associations.map(&:id2)

    high = now - (5 * day)
    low = now - (14 * day)
    associations = client.association.time_range(user.id, "friend", high: high, low: low).value!
    assert_equal 10, associations.size
    associations.each { |association|
      assert association.time.to_i >= low.to_i, "#{association.time} was not >= #{low}"
      assert association.time.to_i <= high.to_i, "#{association.time} was not <= #{high}"
    }
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
  end

  def objects_count
    GitHub::SQL.value("SELECT COUNT(*) FROM tao_objects")
  end

  def associations_count
    GitHub::SQL.value("SELECT COUNT(*) FROM tao_associations")
  end
end
