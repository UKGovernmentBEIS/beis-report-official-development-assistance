module Export
  class S3DownloaderError < StandardError; end

  class S3Downloader
    def initialize(filename:)
      @config = S3UploaderConfig.new(use_public_bucket: false)
      @client = Aws::S3::Client.new(
        region: config.region,
        credentials: Aws::Credentials.new(
          config.key_id,
          config.secret_key
        )
      )
      @filename = filename
    end

    def download
      client.get_object(
        bucket: config.bucket,
        key: filename,
        response_content_type: "text/csv"
      ).body.read
    rescue => error
      raise_error(error.message)
    end

    private

    attr_reader :config, :client, :filename

    def raise_error(original_message = nil)
      raise S3DownloaderError, [original_message, I18n.t("download.failure", filename: filename)].join(" ")
    end
  end
end
