require 'digest/md5'

module Paperclip::Imgix
  class Source
    attr_reader :domain_name, :type

    def self.canonical_type(type)
      type.to_s.downcase.tr('_', '').to_sym
    end

    def self.valid_type?(type)
      [:webfolder, :webproxy, :s3].include?(canonical_type(type))
    end

    def self.create(opts)
      opts = opts.stringify_keys
      if opts && !opts['domain_name'].blank? && valid_type?(opts['type'])
        new(opts)
      end
    end

    def initialize(options)
      @domain_name = options['domain_name']
      @type = self.class.canonical_type(options['type'])
      @secure_url_token = options['secure_url_token']

      case @type
      when :webfolder, :s3
        @base_url = URI.parse(options['prefix'] || options['base_url'] || '/')
      when :webproxy
        @asset_paths = ActionView::AssetPaths.new(Rails.application.config.action_controller)
      else
        raise Paperclip::Imgix::Errors::InvalidSourceType
      end
    end

    def url(attachment, style, options={})
      query = style.query(@attachment, options)
      if query.blank?
        attachment.url(:original, options)
      else
        path = case @type
               when :webfolder, :s3
                 url = URI.parse(attachment.url(:original, options))
                 if @base_url.path.empty?
                   url.path
                 else
                   unless url.path.start_with?(@base_url.path)
                     raise Paperclip::Imgix::Errors::AssetPathMismatach 
                   end
                   url.path[@base_url.path.length..-1]
                 end
               when :webproxy
                 url = URI.parse(path_to_image(attachment.url(:original, options)))
                 raise Paperclip::Imgix::Errors::AssetHostRequired if url.host.blank?
                 url.to_s
               end

        path = "/#{path}" unless path[0] == ?/
        path << "?" << query
        if @secure_url_token
          signature = Digest::MD5.hexdigest(@secure_url_token + path)
          path << "&s=" << signature
        end

        "http://#{@domain_name}.imgix.net#{path}"
      end
    end

    private

    def path_to_image(source)
      @asset_paths.compute_public_path(source, '/')
    end

  end
end
