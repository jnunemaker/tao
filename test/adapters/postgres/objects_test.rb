require 'test_helper'
require "tao/adapters/postgres/objects"

class ObjectPostgresAdapterTest < Minitest::Test
  attr_reader :objects

  def setup
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE tao_objects")
    @objects = Tao::Adapters::Postgres::Objects.new
  end

  def test_get
    data = {
      "name" => "John Nunemaker",
      "username" => "jnunemaker",
    }
    object = objects.create("user", data).value!
    read_object = objects.get(object.id).value!
    assert_instance_of Tao::Object, object
    assert_equal "user", object.type
    assert_equal object.id, read_object.id
    assert_equal "John Nunemaker", object.data.fetch("name")
    assert_equal "jnunemaker", object.data.fetch("username")
  end

  def test_get_does_not_exist_in_database
    assert_nil objects.get(99).value!
  end

  def test_create
    object = objects.create("user").value!
    assert_instance_of Tao::Object, object
    assert_equal 1, objects_count
    assert_equal "user", object.type
    assert_equal GitHub::SQL.value("select id from tao_objects"), object.id
  end

  def test_create_with_data
    data = {
      "name" => "John Nunemaker",
      "username" => "jnunemaker",
    }
    object = objects.create("user", data).value!
    assert_instance_of Tao::Object, object
    assert_equal 1, objects_count
    assert_equal "user", object.type
    assert_equal "John Nunemaker", object.data.fetch("name")
    assert_equal "jnunemaker", object.data.fetch("username")
  end

  def test_update
    data = {
      "name" => "John Nunemaker",
      "username" => "jnunemaker",
    }
    object = objects.create("user", data).value!

    assert objects.update(object.id, "name" => "Foo").value!
    assert_equal 1, objects_count

    updated_object = objects.get(object.id).value!
    assert_equal object.id, updated_object.id
    assert_equal "user", updated_object.type
    assert_equal "Foo", updated_object.data.fetch("name")

    # update rewrites entire value so provide whatever you need
    assert !updated_object.data.key?("username")
  end

  def test_update_does_not_exist_in_database
    assert !objects.update(1, "name" => "Nope").value!
  end

  def test_delete
    object = objects.create("user").value!
    assert objects.delete(object.id).value!
    assert_equal 0, objects_count
  end

  def test_delete_does_not_exist_in_database
    assert !objects.delete(1).value!
  end

  def test_can_create_read_update_and_delete_objects
    client = Tao::Client.new
    object = objects.create("user").value!
    assert_instance_of Tao::Object, object
    assert_equal "user", object.type
    assert object.id > 0, "#{object.id} expected to be greater than 0, but was not"
    assert_equal 1, objects_count

    read_object = objects.get(object.id).value!
    assert_instance_of Tao::Object, object
    assert_equal "user", read_object.type
    assert_equal object.id, read_object.id

    assert objects.update(object.id, foo: "bar").value!
    updated_object = objects.get(object.id).value!
    assert_instance_of Tao::Object, updated_object
    assert_equal "user", updated_object.type
    assert_equal object.id, updated_object.id
    assert_equal "bar", updated_object.data["foo"]

    objects.delete(object.id)
    assert_nil objects.get(object.id).value!
  end

  private

  def objects_count
    GitHub::SQL.value("SELECT COUNT(*) FROM tao_objects")
  end
end
