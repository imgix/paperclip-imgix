require "paperclip"
require "paperclip-imgix/version"
require "paperclip-imgix/style"
require "paperclip-imgix/url_generator"
require "paperclip-imgix/interpolations"
require "paperclip-imgix/railtie"

module Paperclip::Imgix
  def self.create_config(value, env=nil)
    value ||= Paperclip::Attachment.default_options[:imgix]
    value = value.call if value.respond_to?(:call)
    value = case value
            when File
              YAML::load(ERB.new(File.read(value.path)).result)
            when String, Pathname
              YAML::load(ERB.new(File.read(value)).result)
            when Hash
              value
            end
    unless !value.is_a?(Hash) or value.empty?
      value.stringify_keys!
      env = Rails.env if env.blank?
      (value[env] || value).symbolize_keys
    end
  end

  module ClassMethods
    def has_attached_file(name, options = {})
      imgix = Paperclip::Imgix.create_config(options[:imgix])
      if imgix
        options = options.dup
        options[:imgix] = imgix
        options[:url_generator] = Paperclip::Imgix::UrlGenerator
        options[:interpolator] = Paperclip::Imgix::Interpolations
        if options[:styles]
          options[:imgix_styles] = options.delete(:styles).inject({}) do |styles,(name,opts)|
            styles[name] = Paperclip::Imgix::Style.new(opts, options[:processors])
            styles
          end
        end
      end
      super(name, options)
    end
  end
end
