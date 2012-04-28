require "paperclip"
require "paperclip-imgix/version"
require "paperclip-imgix/source"
require "paperclip-imgix/style"
require "paperclip-imgix/url_generator"
require "paperclip-imgix/interpolations"
require "paperclip-imgix/railtie"

module Paperclip::Imgix
  def self.source(value, env=nil)
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
    if value.is_a?(Hash) && !value.empty?
      value.stringify_keys!
      env = Rails.env if env.blank?
      Paperclip::Imgix::Source.create(value[env] || value)
    end
  end

  module ClassMethods
    def has_attached_file(name, options = {})
      source = Paperclip::Imgix.source(options[:imgix])
      if source
        options = options.dup
        options[:imgix] = source
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
