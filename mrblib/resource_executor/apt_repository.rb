module ::MItamae
  module Plugin
    module ResourceExecutor
      class AptRepository < ::MItamae::ResourceExecutor::File
        ParsePlatformError = Class.new(StandardError)

        private

        def set_desired_attributes(desired, action)
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

        class RenderContext
          def initialize(resource)
            @resource = resource
            @entry    = []
            @platform = {}

            if ::File.exist?('/etc/os-release')
              ::File.open('/etc/os-release').each do |line|
                case line
                when /^ID=([a-zA-Z]+)$/
                  @platform[:distrib]       ||= $1.downcase
                when /^VERSION_ID=([0-9]+)\.([0-9]+)$/
                  @platform[:release]       ||= "#{$1}.#{$2}"
                  @platform[:major_version] ||= $1
                  @platform[:minor_version] ||= $2
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

            @resource.entry.each do |repo|
              if repo.source
                deb_padding = 7
              end

              if repo.mirror_uri.kind_of?(String) and repo.mirror_uri.match(/^(?:file|https?):\/\//)
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
        end
      end
    end
  end
end
