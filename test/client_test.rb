require 'test_helper'

class TaoClientTest < Minitest::Test
  def test_initialize
    client = Tao::Client.new
    assert_instance_of Tao::Adapters::Postgres::Object, client.object
    assert_instance_of Tao::Adapters::Postgres::Association, client.association
  end
end
