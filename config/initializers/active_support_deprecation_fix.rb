module ActiveSupport
  class Deprecated
    class DeprecatedConstantProxy < Module
      # Remove "SourceAnnotationExtractor is deprecated" warnings that were
      # interfering with pry's tab complete
      #
      # REMOVE AFTER Rails 6.0.4 RELEASE (https://github.com/rails/rails/pull/37468)
      delegate :hash, :instance_methods, :name, :respond_to?, to: :target
    end
  end
end
