module Export
  class S3UploadError < StandardError; end

  class S3Uploader
    def initialize(file:, filename:)
      @client = Aws::S3::Client.new(
        region: S3UploaderConfig.region,
        credentials: Aws::Credentials.new(
          S3UploaderConfig.key_id,
          S3UploaderConfig.secret_key
        )
      )
      @file = file
      @filename = timestamped_filename(filename)
    end

    attr_reader :client, :file, :filename

    def upload
      response = client.put_object(
        bucket: S3UploaderConfig.bucket,
        key: filename,
        body: file
      )
      raise "Unexpected response." unless response&.etag

      OpenStruct.new(
        url: bucket.object(filename).public_url,
        timestamped_filename: filename
      )
    rescue => error
      raise_error(error.message)
    end

    private

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
      resource.bucket(S3UploaderConfig.bucket)
    end
  end
end
