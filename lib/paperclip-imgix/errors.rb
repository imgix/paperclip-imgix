module Paperclip::Imgix
  module Errors
    class StorageMethodNotSupported < Paperclip::Error
    end

    class InvalidSourceType < Paperclip::Error
    end

    class AssetHostRequired < Paperclip::Error
    end

    class AssetPathMismatach < Paperclip::Error
    end
  end
end
