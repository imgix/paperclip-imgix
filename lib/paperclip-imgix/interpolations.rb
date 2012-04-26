require "paperclip-imgix"

module Paperclip::Imgix
  module Interpolations
    extend Paperclip::Interpolations
    extend self

    def self.all
      Paperclip::Interpolations.all
    end

    def self.interpolate pattern, *args
      pattern = args.first.instance.send(pattern) if pattern.kind_of? Symbol
      all.reverse.inject(pattern) do |result, tag|
        result.gsub(/:#{tag}/) do |match|
          send( tag, *args )
        end
      end
    end

    RIGHT_HERE = "#{__FILE__.gsub(%r{^\./}, "")}:#{__LINE__ + 3}"
    def url attachment, style_name
      raise Errors::InfiniteInterpolationError if caller.any?{|b| b.index(RIGHT_HERE) }
      attachment.url(style_name, :timestamp => false, :escape => false, :is_path_interpolation => true)
    end
  end
end
