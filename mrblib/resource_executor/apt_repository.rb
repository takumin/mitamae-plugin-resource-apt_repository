module ::MItamae
  module Plugin
    module ResourceExecutor
      class AptRepository < ::MItamae::ResourceExecutor::File
        ParsePlatformError = Class.new(StandardError)
        TemplateNotFoundError = Class.new(StandardError)

        private

        def set_desired_attributes(desired, action)
          desired.owner = 'root'
          desired.group = 'root'
          desired.mode  = '0644'

          case action
          when :create
            desired.content = RenderContext.new(attributes).render_file(template_path)
          end

          super
        end

        def template_path
          fragment_path = [
            'plugins',
            'mitamae-plugin-resource-' + self.class.to_s.split('::').last.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase,
            'mrblib',
            'template',
            'apt.list.erb',
          ]

          unless File.exists?(fragment_path.join('/'))
            raise TemplateNotFoundError, "template file not found (file path: #{fragment_path.join('/')})"
          end

          fragment_path.join('/')
        end

        def content_file
          nil
        end

        class RenderContext
          def initialize(resource)
            @resource = resource

            @repos         = {}
            @repos[:name]  = resource.name
            @repos[:entry] = []

            @platform = {}

            ::File.open('/etc/lsb-release').each do |line|
              case line
              when /^DISTRIB_ID=([a-zA-Z]+)$/
                @platform[:distrib] = $1.downcase
              when /^DISTRIB_RELEASE=([0-9]+)\.([0-9]+)$/
                @platform[:release]       ||= "#{$1}.#{$2}"
                @platform[:major_version] ||= $1
                @platform[:minor_version] ||= $2
              when /^DISTRIB_CODENAME=([a-zA-Z]+)$/
                @platform[:codename] = $1.downcase
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

          def render_file(src)
            deb_padding = 3
            url_padding = 0
            suite_padding = 0

            @resource.entry.each do |repo|
              if repo.source
                deb_padding = 7
              end

              if repo.mirror_uri.kind_of?(String) and repo.mirror_uri.match(/^https?:\/\//)
                repo.uri = repo.mirror_uri
              else
                repo.uri = repo.default_uri
              end

              repo.uri = repo.uri.gsub(/###platform_distrib###/, @platform[:distrib])
              repo.uri = repo.uri.gsub(/###platform_release###/, @platform[:release])
              repo.uri = repo.uri.gsub(/###platform_codename###/, @platform[:codename])
              repo.uri = repo.uri.gsub(/###platform_major_version###/, @platform[:major_version])
              repo.uri = repo.uri.gsub(/###platform_minor_version###/, @platform[:minor_version])

              repo.suite = repo.suite.gsub(/###platform_distrib###/, @platform[:distrib])
              repo.suite = repo.suite.gsub(/###platform_release###/, @platform[:release])
              repo.suite = repo.suite.gsub(/###platform_codename###/, @platform[:codename])
              repo.suite = repo.suite.gsub(/###platform_major_version###/, @platform[:major_version])
              repo.suite = repo.suite.gsub(/###platform_minor_version###/, @platform[:minor_version])

              if url_padding < repo.uri.length
                url_padding = repo.uri.length
              end

              if suite_padding < repo.suite.length
                suite_padding = repo.suite.length
              end
            end

            deb_padding += 1
            url_padding += 1

            @resource.entry.each do |repo|
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
              @repos[:entry] << deb

              if repo.source
                deb = 'deb-src'.ljust(deb_padding)
                deb << options
                deb << repo.uri.ljust(url_padding)
                deb << repo.suite.ljust(suite_padding)
                deb << components
                @repos[:entry] << deb
              end
            end

            ERB.new(File.read(src), nil, '-').result(self)
          end
        end
      end
    end
  end
end
