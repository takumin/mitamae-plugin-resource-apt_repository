module ::MItamae
  module Plugin
    module Resource
      class AptRepository < ::MItamae::Resource::File
        class Entry < ::MItamae::Resource::Base
          self.defined_attributes = {}

          define_attribute :uri, type: String, required: true
          define_attribute :suite, type: String, required: true
          define_attribute :components, type: Array
          define_attribute :source, type: [TrueClass, FalseClass]

          # Options of sources.list(5): one-line option name and deb822 field name
          OPTIONS = {
            architectures:               { key: 'arch',                        field: 'Architectures',               type: Array },
            languages:                   { key: 'lang',                        field: 'Languages',                   type: Array },
            targets:                     { key: 'target',                      field: 'Targets',                     type: Array },
            pdiffs:                      { key: 'pdiffs',                      field: 'PDiffs',                      type: [TrueClass, FalseClass] },
            by_hash:                     { key: 'by-hash',                     field: 'By-Hash',                     type: [TrueClass, FalseClass, String] },
            allow_insecure:              { key: 'allow-insecure',              field: 'Allow-Insecure',              type: [TrueClass, FalseClass] },
            allow_weak:                  { key: 'allow-weak',                  field: 'Allow-Weak',                  type: [TrueClass, FalseClass] },
            allow_downgrade_to_insecure: { key: 'allow-downgrade-to-insecure', field: 'Allow-Downgrade-To-Insecure', type: [TrueClass, FalseClass] },
            trusted:                     { key: 'trusted',                     field: 'Trusted',                     type: [TrueClass, FalseClass] },
            signed_by:                   { key: 'signed-by',                   field: 'Signed-By',                   type: [String, Array] },
            check_valid_until:           { key: 'check-valid-until',           field: 'Check-Valid-Until',           type: [TrueClass, FalseClass] },
            valid_until_min:             { key: 'valid-until-min',             field: 'Valid-Until-Min',             type: Integer },
            valid_until_max:             { key: 'valid-until-max',             field: 'Valid-Until-Max',             type: Integer },
            check_date:                  { key: 'check-date',                  field: 'Check-Date',                  type: [TrueClass, FalseClass] },
            date_max_future:             { key: 'date-max-future',             field: 'Date-Max-Future',             type: Integer },
            inrelease_path:              { key: 'inrelease-path',              field: 'InRelease-Path',              type: String },
            snapshot:                    { key: 'snapshot',                    field: 'Snapshot',                    type: String },
          }

          OPTIONS.each_pair do |name, option|
            define_attribute name, type: option[:type]
          end
        end

        define_attribute :entry, type: Array, element: Entry, required: true
        define_attribute :header, type: [String, Array]
        define_attribute :footer, type: [String, Array]

        self.available_actions = [:create, :delete]
      end
    end
  end
end
