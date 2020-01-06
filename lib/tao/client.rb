require "tao/serializers/json"
require "tao/adapters/postgres"

module Tao
  class Client
    attr_reader :object
    attr_reader :association

    def initialize(serializer: Serializers::Json)
      @object = Adapters::Postgres::Object.new(serializer: serializer)
      @association = Adapters::Postgres::Association.new(serializer: serializer)
    end
  end
end
