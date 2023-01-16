module Export
  class S3DownloaderError < StandardError; end

  class S3Downloader
    def initialize(filename:)
      @client = Aws::S3::Client.new(
        region: S3UploaderConfig.region,
        credentials: Aws::Credentials.new(
          S3UploaderConfig.key_id,
          S3UploaderConfig.secret_key
        )
      )
      @filename = filename
    end

    attr_reader :client, :filename

    def download
      client.get_object(
        bucket: S3UploaderConfig.bucket,
        key: filename,
        response_content_type: "text/csv"
      ).body.read
    rescue => error
      raise_error(error.message)
    end

    private

    def raise_error(original_message = nil)
      raise S3DownloaderError, [original_message, "Error generating download for #{filename}"].join(" ")
    end
  end
end
