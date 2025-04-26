# frozen_string_literal: true

module Services
  class Base
    include Dry::Monads[:result, :maybe, :try]

    def self.inherited(subclass)
      super
      subclass.include Dry::Monads::Do.for(:call)
    end

    def self.call(**)
      new.call(**)
    end

    def call(**)
      raise NotImplementedError
    end
  end
end
