require 'test_helper'

class AssociationPostgresAdapterTest < Minitest::Test
  def setup
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE tao_associations")
  end

  def test_can_create_get_change_type_and_delete_association
    client = Tao::Client.new

    association = client.associations.create(id1, friend_type, id2).value!
    assert_instance_of Tao::Association, association
    assert_equal 1, associations_count
    now = Time.now.utc

    friend_associations = client.associations.get(id1, friend_type, [id2]).value!
    assert_instance_of Array, friend_associations
    friend_association = friend_associations.first
    assert_instance_of Tao::Association, friend_association
    assert_equal id1, friend_association.id1
    assert_equal friend_type, friend_association.type
    assert_equal id2, friend_association.id2
    assert_in_delta now, friend_association.time, 2

    result = client.associations.change_type(id1, friend_type, id2, enemy_type).value!
    assert result
    assert_equal 1, associations_count

    enemy_associations = client.associations.get(id1, enemy_type, [id2]).value!
    assert_instance_of Array, enemy_associations
    enemy_association = enemy_associations.first
    assert_instance_of Tao::Association, enemy_association
    assert_equal id1, enemy_association.id1
    assert_equal enemy_type, enemy_association.type
    assert_equal id2, enemy_association.id2
    assert_in_delta now, enemy_association.time, 2

    assert client.associations.delete(id1, enemy_type, id2).value!
  end

  def test_can_create_association_with_time_and_data
    client = Tao::Client.new
    time = Time.now.utc - 60
    data = {"foo" => "bar"}
    association = client.associations.create(id1, friend_type, id2, time, data).value!
    assert_instance_of Tao::Association, association
    assert_equal 1, associations_count
    assert_equal time, association.time
    assert_equal data, association.data
  end

  def test_assocation_querying
    day = 60 * 60 * 24
    now = Time.now.utc
    client = Tao::Client.new
    friend_ids = []

    (1..100).each do |n|
      friend_id = n + 100
      friend_ids << friend_id
      time = now - (n * day)
      client.associations.create(id1, friend_type, friend_id, time).value!
    end

    assert_equal 100, client.associations.count(id1, friend_type).value!
    assert_equal 0, client.associations.count(friend_ids.first, friend_type).value!

    batch_friend_ids = friend_ids[11..20]
    associations = client.associations.get(id1, friend_type, batch_friend_ids).value!
    assert_equal 10, associations.size
    associations.each do |association|
      assert_equal id1, association.id1
      assert_equal friend_type, association.type
      assert_includes friend_ids, association.id2
    end

    associations = client.associations.get(id1, friend_type, friend_ids, high: now - (5 * day)).value!
    assert_equal 96, associations.size

    associations = client.associations.get(id1, friend_type, friend_ids, low: now - (5 * day)).value!
    assert_equal 5, associations.size

    associations = client.associations.range(id1, friend_type, offset: 10).value!
    assert_equal 90, associations.size

    associations = client.associations.range(id1, friend_type, offset: 10, limit: 10).value!
    assert_equal 10, associations.size
    assert_equal friend_ids[10..19], associations.map(&:id2)

    high = now - (5 * day)
    low = now - (14 * day)
    associations = client.associations.time_range(id1, friend_type, high: high, low: low).value!
    assert_equal 10, associations.size
    associations.each { |association|
      assert association.time.to_i >= low.to_i, "#{association.time} was not >= #{low}"
      assert association.time.to_i <= high.to_i, "#{association.time} was not <= #{high}"
    }
  end

  private

  def associations_count
    GitHub::SQL.value("SELECT COUNT(*) FROM tao_associations")
  end

  def id1
    1
  end

  def id2
    2
  end

  def friend_type
    "friend"
  end

  def enemy_type
    "enemy"
  end
end
