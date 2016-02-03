module Fastlane
  module Actions
    module SharedValues
    end

    class SparkleAddUpdateAction < Action

      # inspired by https://github.com/CocoaPods/CocoaPods-app/blob/578555e8e86a5f7fe3e56deeb5406ffb24e1541e/Rakefile#L1069

      def self.run(params)

        # UI.message "#{params[:feed_file]}"
        # UI.message "#{params[:app_download_url]}"
        # UI.message "#{params[:app_size]}"
        # UI.message "#{params[:machine_version]}"
        # UI.message "#{params[:human_version]}"
        # UI.message "#{params[:title]}"
        # UI.message "#{params[:release_notes_link]}"
        # UI.message "#{params[:deployment_target]}"

        xml_file = params[:feed_file]

        # Load existing sparkle xml feed file
        require 'rexml/document'
        doc = REXML::Document.new(File.read(xml_file))
        channel = doc.elements['/rss/channel']

        # Verify that the new version is strictly greater than the last one in the list
        last_version = channel.elements.select { |e| e.name == 'item' }.last.get_elements('enclosure').first.attributes['version']
        raise "You must update the machine version to be above #{last_version}!" unless params[:machine_version] > last_version

        # Add a new item to the Appcast feed
        item = channel.add_element('item')
        item.add_element("title").add_text(params[:title])
        item.add_element("sparkle:minimumSystemVersion").add_text(params[:deployment_target]) if params[:deployment_target]
        item.add_element("sparkle:releaseNotesLink").add_text(params[:release_notes_link])
        item.add_element("pubDate").add_text(DateTime.now.strftime("%a, %d %h %Y %H:%M:%S %z"))

        enclosure = item.add_element("enclosure")
        enclosure.attributes["type"] = "application/octet-stream"
        enclosure.attributes["sparkle:version"] = params[:machine_version]
        enclosure.attributes["sparkle:shortVersionString"] = params[:human_version]
        enclosure.attributes["length"] = params[:app_size]
        enclosure.attributes["url"] = params[:app_download_url]
        
        # Write it back out
        formatter = REXML::Formatters::Pretty.new(2)
        formatter.compact = true
        new_xml = ""
        formatter.write(doc, new_xml)
        File.open(xml_file, 'w') { |file| file.write new_xml }

      end

      #####################################################
      # @!group Documentation
      #########################################s############

      def self.description
        "Adds a new version entry into your Sparkle XML feed file"
      end

      def self.details
        ""
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :feed_file,
                                       env_name: "FL_SPARKLE_ADD_UPDATE_FEED_FILE",
                                       description: "Path to the xml feed file",
                                       default_value: "sparkle.xml",
                                       verify_block: proc do |value|
                                          raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :app_download_url,
                                       env_name: "FL_SPARKLE_ADD_UPDATE_APP_DOWNLOAD_URL",
                                       description: "Download URL of the app update",
                                       verify_block: proc do |value|
                                          raise "Invalid URL '#{value}'".red unless (value and !value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :app_size,
                                       env_name: "FL_SPARKLE_ADD_UPDATE_APP_SIZE",
                                       description: "App's size in bytes"),          
          FastlaneCore::ConfigItem.new(key: :title,
                                       env_name: "FL_SPARKLE_ADD_UPDATE_TITLE",
                                       description: "Update title",
                                       verify_block: proc do |value|
                                          raise "Invalid title '#{value}'".red unless (value and !value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :release_notes_link,
                                       env_name: "FL_SPARKLE_ADD_UPDATE_RELEASE_NOTES_LINK",
                                       description: "Update release notes link",
                                       verify_block: proc do |value|
                                          raise "Invalid release notes link '#{value}'".red unless (value and !value.empty?)
                                       end),          
          FastlaneCore::ConfigItem.new(key: :machine_version,
                                       env_name: "FL_SPARKLE_ADD_UPDATE_MACHINE_VERSION",
                                       description: "Machine version, must be strictly greater than the previous one",
                                       verify_block: proc do |value|
                                          raise "Invalid machine version '#{value}'".red unless (value and !value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :human_version,
                                       env_name: "FL_SPARKLE_ADD_UPDATE_HUMAN_VERSION",
                                       description: "Human version string, defaults to machine version",
                                       verify_block: proc do |value|
                                          raise "Invalid human version '#{value}'".red unless (value and !value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :deployment_target,
                                       env_name: "FL_SPARKLE_ADD_UPDATE_DEPLOYMENT_TARGET",
                                       description: "Update's deployment target",
                                       optional: true)
        ]
      end

      def self.output
        []
      end

      def self.return_value
      end

      def self.authors
        ["czechboy0"]
      end

      def self.is_supported?(platform)
        platform == :mac
      end
    end
  end
end
