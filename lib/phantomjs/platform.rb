module Phantomjs
  class Platform
    class << self
      def host_os
        RbConfig::CONFIG['host_os']
      end

      def architecture
        RbConfig::CONFIG['host_cpu']
      end

      def phantomjs_path
        File.expand_path File.join(Phantomjs.base_dir, platform, 'bin/phantomjs')
      end

      def installed?
        File.exist? phantomjs_path
      end

      # TODO: Clean this up, it looks like a pile of...
      def install!
        STDERR.puts "Phantomjs does not appear to be installed in #{phantomjs_path}, installing!"
        FileUtils.mkdir_p Phantomjs.base_dir

        # Purge temporary directory if it is still hanging around from previous installs,
        # then re-create it.
        temp_dir = File.join('/tmp', 'phantomjs_install')
        FileUtils.rm_rf temp_dir
        FileUtils.mkdir_p temp_dir

        Dir.chdir temp_dir do
          unless system "wget #{package_url}"
            raise "Failed to load phantomjs from #{package_url} :("
          end

          case package_url.split('.').last
            when 'bz2'
              system "bunzip2 #{File.basename(package_url)}"
              system "tar xf #{File.basename(package_url).sub(/\.bz2$/, '')}"
            when 'zip'
              system "unzip #{File.basename(package_url)}"
            else
              raise "Unknown compression format for #{File.basename(package_url)}"
          end

          # Find the phantomjs build we just extracted
          extracted_dir = Dir['phantomjs*'].find { |path| File.directory?(path) }

          # Move the extracted phantomjs build to $HOME/.phantomjs/version/platform
          FileUtils.mv extracted_dir, File.join(Phantomjs.base_dir, platform)

          # Clean up remaining files in tmp
          FileUtils.rm_rf temp_dir
        end

        raise "Failed to install phantomjs. Sorry :(" unless File.exist?(phantomjs_path)
      end

      def ensure_installed!
        install! unless installed?
      end
    end

    class Linux64 < Platform
      class << self
        def useable?
          host_os.include?('linux') and architecture.include?('x86_64')
        end

        def platform
          'x86_64-linux'
        end

        def package_url
          'http://phantomjs.googlecode.com/files/phantomjs-1.6.0-linux-x86_64-dynamic.tar.bz2'
        end
      end
    end

    class Linux32 < Platform
      class << self
        def useable?
          host_os.include?('linux') and (architecture.include?('x86_32') or architecture.include?('i686'))
        end

        def platform
          'x86_32-linux'
        end

        def package_url
          'http://phantomjs.googlecode.com/files/phantomjs-1.6.0-linux-i686-dynamic.tar.bz2'
        end
      end
    end

    class OsX < Platform
      class << self
        def useable?
          host_os.include?('darwin')
        end

        def platform
          'darwin'
        end

        def package_url
          'http://phantomjs.googlecode.com/files/phantomjs-1.6.0-macosx-static.zip'
        end
      end
    end
  end
end
