module Export
  class S3UploadError < StandardError; end

  class S3Uploader
    def initialize(file)
      @client = Aws::S3::Client.new
      @file = file
      @filename = "export-file-#{Time.current.to_formatted_s(:number)}.csv"
    end

    attr_reader :client, :file, :filename

    def upload
      response = client.put_object(
        bucket: S3UploaderConfig.bucket,
        key: filename,
        body: file
      )
      raise "Unexpected response." unless response&.etag

      bucket.object(filename).public_url
    rescue => error
      raise_error(error.message)
    end

    private

    def raise_error(original_message = nil)
      raise S3UploadError, [original_message, "Error uploading report #{filename}"].join(" ")
    end

    def bucket
      resource = Aws::S3::Resource.new(client: client)
      resource.bucket(S3UploaderConfig.bucket)
    end
  end
end
