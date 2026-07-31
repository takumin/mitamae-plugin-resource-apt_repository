module ::MItamae
  module Plugin
    module ResourceExecutor
      class AptRepository < ::MItamae::ResourceExecutor::File
        ParsePlatformError = Class.new(StandardError)

        private

        def set_desired_attributes(desired, action)
          validate_element_attributes

          desired.owner = 'root'
          desired.group = 'root'
          desired.mode  = '0644'

          case action
          when :create
            desired.content = RenderContext.new(attributes).render_file()
          end

          super
        end

        def content_file
          nil
        end

        def validate_element_attributes
          @resource.class.defined_attributes.each_pair do |name, options|
            next unless options[:element]

            sname = name.to_s
            next unless attributes.has_key?(sname)

            attributes[sname].each_with_index do |element, index|
              validate_element(options[:element], element, "#{sname}[#{index}]")
            end
          end
        end

        def validate_element(element_class, element, label)
          unless element.is_a?(::Hash)
            raise ::MItamae::Resource::InvalidTypeError, "#{label} should be Hash."
          end

          element.each_key do |key|
            unless element_class.defined_attributes.has_key?(key.to_sym)
              raise ::MItamae::Resource::InvalidTypeError, "'#{label}.#{key}' is not a valid attribute."
            end
          end

          element_class.defined_attributes.each_pair do |key, details|
            skey = key.to_s

            unless element.has_key?(skey)
              if details[:required]
                raise ::MItamae::Resource::AttributeMissingError, "'#{label}.#{skey}' attribute is required but it is not set."
              end
              next
            end

            valid_type = [details[:type]].flatten.any? do |type|
              element[skey].is_a?(type)
            end
            unless valid_type
              raise ::MItamae::Resource::InvalidTypeError, "#{label}.#{skey} attribute should be #{details[:type]}."
            end
          end
        end

        class RenderContext
          Repo = Struct.new(:uri, :suite, :components, :options, :source)

          def initialize(resource)
            @resource = resource
            @entry    = []
            @platform = {}

            if ::File.exist?('/etc/os-release')
              ::File.open('/etc/os-release').each do |line|
                case line
                when /^ID=([a-zA-Z]+)$/
                  @platform[:distrib]       ||= $1.downcase
                when /^VERSION_ID="?([0-9]+)\.?([0-9]+)?"?$/
                  @platform[:release]       ||= "#{$1}.#{$2}"
                  @platform[:major_version] ||= $1
                  @platform[:minor_version] ||= $2 || "0"
                when /^VERSION_CODENAME=([a-zA-Z]+)$/
                  @platform[:codename]      ||= $1.downcase
                end
              end
            end

            if ::File.exist?('/etc/lsb-release')
              ::File.open('/etc/lsb-release').each do |line|
                case line
                when /^DISTRIB_ID=([a-zA-Z]+)$/
                  @platform[:distrib]       ||= $1.downcase
                when /^DISTRIB_RELEASE=([0-9]+)\.([0-9]+)$/
                  @platform[:release]       ||= "#{$1}.#{$2}"
                  @platform[:major_version] ||= $1
                  @platform[:minor_version] ||= $2
                when /^DISTRIB_CODENAME=([a-zA-Z]+)$/
                  @platform[:codename]      ||= $1.downcase
                end
              end
            end

            unless @platform[:distrib].kind_of?(String) and @platform[:distrib] != ''
              raise ParsePlatformError, "Unknown Platform Distrib"
            end

            unless @platform[:release].kind_of?(String) and @platform[:release] != ''
              raise ParsePlatformError, "Unknown Platform Release"
            end

            unless @platform[:codename].kind_of?(String) and @platform[:codename] != ''
              raise ParsePlatformError, "Unknown Platform Codename"
            end

            unless @platform[:major_version].kind_of?(String) and @platform[:major_version] != ''
              raise ParsePlatformError, "Unknown Platform Major Version"
            end

            unless @platform[:minor_version].kind_of?(String) and @platform[:minor_version] != ''
              raise ParsePlatformError, "Unknown Platform Minor Version"
            end
          end

          def render_file
            deb_padding = 3
            url_padding = 0
            suite_padding = 0

            repos = []

            @resource.entry.each do |entry|
              if entry.source
                deb_padding = 7
              end

              if entry.mirror_uri.kind_of?(String) and entry.mirror_uri.match(/^(?:file|https?):\/\//)
                uri = entry.mirror_uri
              else
                uri = entry.default_uri
              end

              repo = Repo.new(
                expand_platform(uri),
                expand_platform(entry.suite),
                entry.components,
                entry.options,
                entry.source
              )

              if url_padding < repo.uri.length
                url_padding = repo.uri.length
              end

              if suite_padding < repo.suite.length
                suite_padding = repo.suite.length
              end

              repos << repo
            end

            deb_padding += 1
            url_padding += 1

            repos.each do |repo|
              options = ''
              if repo.options
                options = "[#{repo.options}] "
              end

              components = ''
              if repo.components
                components = " #{repo.components.join(' ')}"
              end

              deb = 'deb'.ljust(deb_padding)
              deb << options
              deb << repo.uri.ljust(url_padding)
              deb << repo.suite.ljust(suite_padding)
              deb << components
              @entry << deb

              if repo.source
                deb = 'deb-src'.ljust(deb_padding)
                deb << options
                deb << repo.uri.ljust(url_padding)
                deb << repo.suite.ljust(suite_padding)
                deb << components
                @entry << deb
              end
            end

            content = ''
            case @resource.header
            when String
              content << @resource.header + "\n"
            when Array
              content << @resource.header.join("\n") + "\n"
            end
            @entry.each do |repo|
              content << "#{repo}\n"
            end
            case @resource.footer
            when String
              content << @resource.footer + "\n"
            when Array
              content << @resource.footer.join("\n") + "\n"
            end

            return content
          end

          private

          def expand_platform(value)
            value = value.gsub(/###platform_distrib###/, @platform[:distrib])
            value = value.gsub(/###platform_release###/, @platform[:release])
            value = value.gsub(/###platform_codename###/, @platform[:codename])
            value = value.gsub(/###platform_major_version###/, @platform[:major_version])
            value = value.gsub(/###platform_minor_version###/, @platform[:minor_version])
            value
          end
        end
      end
    end
  end
end
