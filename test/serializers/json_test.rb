require 'test_helper'

class JsonSerializerTest < Minitest::Test
  def test_dump
    expected = '{"foo":"bar"}'
    assert_equal expected, Tao::Serializers::Json.dump({'foo' => 'bar'})
  end

  def test_load
    expected = {'foo' => 'bar'}
    assert_equal expected, Tao::Serializers::Json.load('{"foo":"bar"}')
  end
end
