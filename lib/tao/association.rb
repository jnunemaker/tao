module Tao
  class Association
    attr_reader :id1, :type, :id2, :time, :data

    def initialize(id1, type, id2, time = nil, data = {})
      @id1 = id1
      @type = type
      @id2 = id2
      @time = time.utc
      @data = data
    end
  end
end
