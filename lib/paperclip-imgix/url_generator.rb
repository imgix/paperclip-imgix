module Paperclip::Imgix
  class UrlGenerator < Paperclip::UrlGenerator
    def initialize(attachment, attachment_options)
      @attachment = attachment
      @attachment_options = attachment_options
    end

    def for(style_name, options)
      if style_name == :original || options[:is_path_interpolation]
        super
      else
        style = @attachment_options[:imgix_styles][style_name]
        if style
          @attachment.options[:imgix].url(@attachment, style, options)
        else
          super
        end
      end
    end
  end
end
