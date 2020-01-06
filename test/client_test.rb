require 'test_helper'

class TaoClientTest < Minitest::Test
  def test_initialize
    client = Tao::Client.new
    assert_instance_of Tao::Adapters::Postgres::Objects, client.objects
    assert_instance_of Tao::Adapters::Postgres::Associations, client.associations
  end
end
