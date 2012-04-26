module Paperclip::Imgix
  class UrlGenerator < Paperclip::UrlGenerator
    def initialize(attachment, attachment_options)
      @attachment = attachment
      @attachment_options = attachment_options
    end

    def for(style_name, options)
      if options[:is_path_interpolation]
        super
      else
        url = super(:original, :escape => options[:escape])

        style = @attachment_options[:imgix_styles][style_name]
        if style
          query = style.to_query(options[:style])
          query = "?#{query}" unless query.blank?
        else
          query = ''
        end

        "http://localhost:8001/convert/http://localhost:3000#{url}#{query}"
      end
    end
  end
end
