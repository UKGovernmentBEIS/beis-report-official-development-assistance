module Export
  class S3UploadError < StandardError; end

  class S3Uploader
    def initialize(file:, filename:, use_public_bucket:)
      @use_public_bucket = use_public_bucket
      @config = S3UploaderConfig.new(use_public_bucket: use_public_bucket)
      @client = Aws::S3::Client.new(
        region: config.region,
        credentials: Aws::Credentials.new(
          config.key_id,
          config.secret_key
        )
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

      if use_public_bucket
        OpenStruct.new(
          url: bucket.object(filename).public_url,
          timestamped_filename: filename
        )
      else
        OpenStruct.new(timestamped_filename: filename)
      end
    rescue => error
      raise_error(error.message)
    end

    private

    attr_reader :config, :use_public_bucket

    def timestamped_filename(name)
      pathname = Pathname.new(name)
      basename = pathname.basename(".*")
      extension = pathname.extname

      "#{basename}-#{Time.current.to_formatted_s(:number)}#{extension}"
    end

    def raise_error(original_message = nil)
      raise S3UploadError, [original_message, "Error uploading report #{filename}"].join(" ")
    end

    def bucket
      resource = Aws::S3::Resource.new(client: client)
      resource.bucket(config.bucket)
    end
  end
end
