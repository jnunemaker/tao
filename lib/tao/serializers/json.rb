require "json"

module Tao
  module Serializers
    class Json
      def self.dump(data)
        ::JSON.generate(data)
      end

      def self.load(value)
        ::JSON.parse(value)
      end
    end
  end
end
