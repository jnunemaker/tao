require 'test_helper'
require "tao/adapters/postgres/associations"

class AssociationPostgresAdapterTest < Minitest::Test
  attr_reader :associations

  def setup
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE tao_associations")
    @associations = Tao::Adapters::Postgres::Associations.new
  end

  def test_count
    assert_equal 0, associations.count(id1, friend_type).value!

    associations.create(id1, friend_type, id2).value!
    assert_equal 1, associations.count(id1, friend_type).value!

    associations.create(id1, enemy_type, id2).value!
    assert_equal 1, associations.count(id1, enemy_type).value!

    associations.create(id1, friend_type, id2 + 1).value!
    assert_equal 2, associations.count(id1, friend_type).value!
  end

  def test_create
    association = associations.create(id1, friend_type, id2).value!
    assert_instance_of Tao::Association, association
    assert_equal 1, associations_count
    assert_equal id1, association.id1
    assert_equal id2, association.id2
    assert_equal friend_type, association.type
    assert_in_delta Time.now.utc, association.time, 2
  end

  def test_create_with_time
    time = Time.now.utc - 60
    association = associations.create(id1, friend_type, id2, time: time).value!
    assert_instance_of Tao::Association, association
    assert_equal 1, associations_count
    assert_equal id1, association.id1
    assert_equal id2, association.id2
    assert_equal friend_type, association.type
    assert_equal time, association.time
  end

  def test_create_with_data
    data = {"name" => "John Nunemaker"}
    association = associations.create(id1, friend_type, id2, data: data).value!
    assert_instance_of Tao::Association, association
    assert_equal 1, associations_count
    assert_equal id1, association.id1
    assert_equal id2, association.id2
    assert_equal friend_type, association.type
    assert_equal data, association.data
  end

  def test_delete
    association = associations.create(id1, friend_type, id2).value!
    assert associations.delete(id1, friend_type, id2).value!
    assert_equal 0, associations_count
  end

  def test_delete_does_not_exist_in_database
    assert !associations.delete(id1, friend_type, id2).value!
  end

  def test_change_type
    association = associations.create(id1, friend_type, id2).value!
    assert associations.change_type(id1, friend_type, id2, enemy_type).value!
    assert_equal 1, associations_count
    updated_association = associations.get(id1, enemy_type, [id2]).value!
    assert_equal 1, updated_association.size
  end

  def test_change_type_does_not_exist_in_database
    assert !associations.change_type(id1, friend_type, id2, enemy_type).value!
  end

  def test_assocation_querying
    day = 60 * 60 * 24
    now = Time.now.utc
    friend_ids = []

    (1..100).each do |n|
      friend_id = n + 100
      friend_ids << friend_id
      time = now - (n * day)
      associations.create(id1, friend_type, friend_id, time: time).value!
    end

    batch_friend_ids = friend_ids[11..20]
    friend_associations = associations.get(id1, friend_type, batch_friend_ids).value!
    assert_equal 10, friend_associations.size
    friend_associations.each do |association|
      assert_equal id1, association.id1
      assert_equal friend_type, association.type
      assert_includes friend_ids, association.id2
    end

    friend_associations = associations.get(id1, friend_type, friend_ids, high: now - (5 * day)).value!
    assert_equal 96, friend_associations.size

    friend_associations = associations.get(id1, friend_type, friend_ids, low: now - (5 * day)).value!
    assert_equal 5, friend_associations.size

    friend_associations = associations.range(id1, friend_type, offset: 10).value!
    assert_equal 90, friend_associations.size

    friend_associations = associations.range(id1, friend_type, offset: 10, limit: 10).value!
    assert_equal 10, friend_associations.size
    assert_equal friend_ids[10..19], friend_associations.map(&:id2)

    high = now - (5 * day)
    low = now - (14 * day)
    friend_associations = associations.time_range(id1, friend_type, high: high, low: low).value!
    assert_equal 10, friend_associations.size
    friend_associations.each { |association|
      assert association.time.to_i >= low.to_i, "#{association.time} was not >= #{low}"
      assert association.time.to_i <= high.to_i, "#{association.time} was not <= #{high}"
    }
  end

  def test_get_does_not_exist_in_database
    assert_equal [], associations.get(id1, friend_type, [id2]).value!
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
