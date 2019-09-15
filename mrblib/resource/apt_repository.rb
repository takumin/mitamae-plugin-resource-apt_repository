module ::MItamae
  module Plugin
    module Resource
      class AptRepository < ::MItamae::Resource::File
        define_attribute :entry, type: Array, required: true
        define_attribute :header, type: [String, Array]
        define_attribute :footer, type: [String, Array]

        self.available_actions = [:create, :delete]
      end
    end
  end
end
