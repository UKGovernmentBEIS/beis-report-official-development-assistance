module Export
  class S3Uploader
    def initialize(file)
      @client = Aws::S3::Client.new
      @file = file
    end

    attr_reader :client, :file

    def upload
      client.put_object(
        bucket: S3UploaderConfig.bucket,
        body: file
      )
    end
  end
end
