require "tao/serializers/json"
require "tao/adapters/postgres"

module Tao
  class Client
    attr_reader :objects
    attr_reader :associations

    def initialize(serializer: Serializers::Json)
      @objects = Adapters::Postgres::Objects.new(serializer: serializer)
      @associations = Adapters::Postgres::Associations.new(serializer: serializer)
    end
  end
end
