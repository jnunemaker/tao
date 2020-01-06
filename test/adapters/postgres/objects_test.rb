require 'test_helper'
require "tao/adapters/postgres/objects"

class ObjectPostgresAdapterTest < Minitest::Test
  def setup
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE tao_objects")
  end

  def test_can_create_read_update_and_delete_objects
    client = Tao::Client.new
    object = client.objects.create("user").value!
    assert_instance_of Tao::Object, object
    assert_equal "user", object.type
    assert object.id > 0, "#{object.id} expected to be greater than 0, but was not"
    assert_equal 1, objects_count

    read_object = client.objects.get(object.id).value!
    assert_instance_of Tao::Object, object
    assert_equal "user", read_object.type
    assert_equal object.id, read_object.id

    updated_object = client.objects.update(object.id, foo: "bar").value!
    assert_instance_of Tao::Object, object
    assert_equal "user", updated_object.type
    assert_equal object.id, updated_object.id
    assert_equal "bar", updated_object.data["foo"]

    client.objects.delete(object.id)
    assert_nil client.objects.get(object.id).value!
  end

  def objects_count
    GitHub::SQL.value("SELECT COUNT(*) FROM tao_objects")
  end
end
