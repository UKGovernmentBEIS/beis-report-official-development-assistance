module Export
  class S3Config
    def region
      credentials.fetch(:aws_region)
    end

    def bucket
      credentials.fetch(:bucket_name)
    end

    private

    def credentials
      {
        aws_region: "eu-west-2",
        bucket_name: ENV.fetch("EXPORT_DOWNLOAD_S3_BUCKET")
      }
    rescue KeyError => _error
      raise "AWS S3 bucket name not found"
    end
  end
end
