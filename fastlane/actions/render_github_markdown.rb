module Fastlane
  module Actions
    module SharedValues
    end

    class RenderGithubMarkdownAction < Action
      def self.run(params)

        contents = params[:markdown_contents] || File.read(params[:markdown_file])
        raise "You must pass either the markdown contents or a file path" unless contents

        require 'json'
        body = { 
          text: contents, 
          mode: "gfm", 
          context: params[:context_repository] 
          }.to_json

        require 'base64'
        headers = { 
          'User-Agent' => 'fastlane-render_github_markdown',
          'Authorization' => "Basic #{Base64.strict_encode64(params[:api_token])}"
        }
        
        response = Excon.post("https://api.github.com/markdown", headers: headers, body: body)

        raise response[:headers].to_s unless response[:status] == 200
        html_markdown = response.body

        ENV['RENDER_GITHUB_MARKDOWN_HTML'] = html_markdown
        return html_markdown
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Uses the GitHub API to render your GitHub-flavored Markdown as HTML"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :markdown_file,
                                       env_name: "FL_RENDER_GITHUB_MARKDOWN_FILE",
                                       description: "The path to your markdown file",
                                       optional: true,
                                       verify_block: proc do |value|
                                         raise "File doesn't exist '#{value}'".red unless File.exists?(value)
                                       end),          
          FastlaneCore::ConfigItem.new(key: :markdown_contents,
                                       env_name: "FL_RENDER_GITHUB_MARKDOWN_CONTENTS",
                                       optional: true,
                                       description: "The markdown contents"),          
          FastlaneCore::ConfigItem.new(key: :context_repository,
                                       env_name: "FL_RENDER_GITHUB_MARKDOWN_CONTEXT_REPOSITORY",
                                       description: "The path to your repo, e.g. 'fastlane/fastlane'",
                                       verify_block: proc do |value|
                                         raise "Please only pass the path, e.g. 'fastlane/fastlane'".red if value.include? "github.com"
                                         raise "Please only pass the path, e.g. 'fastlane/fastlane'".red if value.split('/').count != 2
                                       end),
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: "FL_RENDER_GITHUB_MARKDOWN_API_TOKEN",
                                       description: "Personal API Token for GitHub - generate one at https://github.com/settings/tokens",
                                       is_string: true,
                                       optional: false),
        ]
      end

      def self.output
        [
          ['RENDER_GITHUB_MARKDOWN_HTML', 'Rendered HTML']
        ]
      end

      def self.return_value
        "Returns the GFM Markdown contents rendered as HTML"
      end

      def self.authors
        ["czechboy0"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
