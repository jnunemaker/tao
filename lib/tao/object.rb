module Tao
  class Object
    attr_reader :type, :id, :data

    def initialize(type, id, data = {})
      @type = type
      @id = id
      @data = data
    end
  end
end
