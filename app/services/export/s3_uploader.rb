module Export
  class S3UploadError < StandardError; end

  class S3Uploader
    def initialize(file:, filename:)
      @bucket_name_from_env_var = ENV.fetch("EXPORT_DOWNLOAD_S3_BUCKET", false)
      @config = S3UploaderConfig.new
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
      @file = file
      @filename = timestamped_filename(filename)
    end

    attr_reader :client, :file, :filename

    def upload
      response = client.put_object(
        bucket: @bucket_name_from_env_var || config.bucket,
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

    def bucket
      resource = Aws::S3::Resource.new(client: client)
      resource.bucket(config.bucket)
    end
  end
end
