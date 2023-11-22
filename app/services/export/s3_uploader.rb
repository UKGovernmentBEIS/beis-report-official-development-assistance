module Export
  class S3UploadError < StandardError; end

  class S3Uploader
    def initialize(file:, filename:)
      @config = S3Config.new
      @client = Aws::S3::Client.new(
        region: config.region,
        credentials: Aws::ECSCredentials.new(retries: 3)
      )
      @file = file
      @filename = timestamped_filename(filename)
    end

    attr_reader :client, :file, :filename

    def upload
      response = client.put_object(
        bucket: config.bucket,
        key: filename,
        body: file
      )
      raise "Unexpected response." unless response&.etag

      OpenStruct.new(timestamped_filename: filename)
    rescue => error
      raise_error(error.message)
    end

    private

    attr_reader :config

    def timestamped_filename(name)
      pathname = Pathname.new(name)
      basename = pathname.basename(".*")
      extension = pathname.extname

      "#{basename}-#{Time.current.to_formatted_s(:number)}#{extension}"
    end

    def raise_error(original_message = nil)
      raise S3UploadError, [original_message, I18n.t("upload.failure", filename: filename)].join(" ")
    end
  end
end
