module JenkinsTracker
  class Base
    #include Util

    attr_reader :changelog, :tracker_client, :job_name, :build_url

    def initialize(options = {})
      raise FileNotFoundError, "Changelog file not found at: #{options[:changelog_file]}" unless File.file?(options[:changelog_file])

      @changelog = File.read(options[:changelog_file])

      @tracker_client = TrackerClient.new(:token => options[:tracker_token])
      @tracker_client.use_ssl = true

      @job_name = options[:job_name]
      @build_url = options[:build_url]
    end

    def integrate_job_with_tracker(project_id)
      parse_changelog.each do |change|
        note = "*#{change.commit_message}* integrated in *#{job_name}* (#{build_url})"
        tracker_client.add_note_to_story(project_id, change.story_id, note)
      end
    end

    def parse_changelog
      results = []

      changelog.scan(/(\[[#a-zA-Z0-9\s]+\])(.*)/) do |ids, msg|
        parse_tracker_story_ids(ids).each do |id|
          results << ChangelogItem.new(:story_id => id, :commit_message => "#{ids}#{msg}".strip)
        end
      end

      results.uniq
    end


    private

    def parse_tracker_story_ids(str)
      str.strip.gsub(/[\[#\]]/, '').split(' ').map(&:to_i).reject { |i| i == 0 }
    end

  end
end
