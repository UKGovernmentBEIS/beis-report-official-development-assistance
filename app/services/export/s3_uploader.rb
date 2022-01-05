module Export
  class S3Uploader
    def initialize(file)
      @client = Aws::S3::Client.new
      @file = file
      @filename = "export-file-#{Time.current.to_formatted_s(:number)}.csv"
    end

    attr_reader :client, :file, :filename

    def upload
      client.put_object(
        bucket: S3UploaderConfig.bucket,
        key: filename,
        body: file
      )
    end
  end
end
