module Export
  class S3UploaderConfig
    def self.region
      credentials.fetch("aws_region")
    end

    def self.bucket
      credentials.fetch("bucket_name")
    end

    def self.key_id
      credentials.fetch("aws_access_key_id")
    end

    def self.secret_key
      credentials.fetch("aws_secret_access_key")
    end

    def self.credentials
      JSON.parse(ENV.fetch("VCAP_SERVICES"))
        .fetch("aws-s3-bucket")
        .find { |config| config.fetch("name").match?(/^s3-export-download-bucket/) }
        .fetch("credentials")
    rescue KeyError, NoMethodError => _error
      raise "AWS S3 credentials not found"
    end
  end
end
