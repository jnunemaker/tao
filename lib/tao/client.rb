require "tao/serializers/json"
require "tao/object_store"
require "tao/association_store"

module Tao
  class Client
    attr_reader :object
    attr_reader :association

    def initialize(serializer: Serializers::Json)
      @object = ObjectStore.new(serializer: serializer)
      @association = AssociationStore.new(serializer: serializer)
    end
  end
end
