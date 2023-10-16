module Export
  class S3DownloaderError < StandardError; end

  class S3Downloader
    def initialize(filename:)
      @config = S3UploaderConfig.new(use_public_bucket: false)
      @bucket_name_from_env_var = ENV.fetch("EXPORT_DOWNLOAD_S3_BUCKET", false)
      @client = if @bucket_name_from_env_var
        Aws::S3::Client.new(
          region: "eu-west-2",
          credentials: Aws::ECSCredentials.new(retries: 3)
        )
      else
        Aws::S3::Client.new(
          region: config.region,
          credentials: Aws::Credentials.new(
            config.key_id,
            config.secret_key
          )
        )
      end
      @filename = filename
    end

    def download
      client.get_object(
        bucket: @bucket_name_from_env_var || config.bucket,
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
