module ::MItamae
  module Plugin
    module Resource
      class AptRepository < ::MItamae::Resource::File
        class Entry < ::MItamae::Resource::Base
          self.defined_attributes = {}

          define_attribute :default_uri, type: String, required: true
          define_attribute :mirror_uri, type: String
          define_attribute :suite, type: String, required: true
          define_attribute :components, type: Array
          define_attribute :options, type: String
          define_attribute :source, type: [TrueClass, FalseClass]
        end

        define_attribute :entry, type: Array, element: Entry, required: true
        define_attribute :header, type: [String, Array]
        define_attribute :footer, type: [String, Array]

        self.available_actions = [:create, :delete]
      end
    end
  end
end
