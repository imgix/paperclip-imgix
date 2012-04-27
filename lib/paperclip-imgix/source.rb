require 'digest/md5'

# TODO: this is a hard-coded hack for now, need to make this actually work :)

module Paperclip::Imgix
  class Source
    attr_reader :name, :type

    def initialize(options)
      options = options.symbolize_keys
      @name = options[:name]
      @type = options[:type]
      @signature_token = options[:signature_token]

      case @type
      when :web_folder
        @base_url = options[:base_url]
      else
        raise "Invalid source type"
      end
    end

    def url(attachment, style, options={})
      orig_url = attachment.url(:original, :escape => true, :timestamp => false)
      query = style.query(@attachment, options)
      path = "#{orig_url.sub('http://s3.amazonaws.com/paperclip-imgix', '')}?#{query}"
      if @signature_token
        signature = Digest::MD5.hexdigest(@signature_token + path)
        path << "&s=" << signature
      end
      "http://paperclip.imgix.net#{path}"
    end

  end
end
