module Paperclip::Imgix
  class Style

    def self.range(key, min, max, round=true)
      proc do |val, par|
        val = val.to_f if val
        if val.is_a?(Numeric)
          if val < min then val = min
          elsif val > max then val = max
          end
          par[key] = round ? val.round : val
        end
      end
    end

    def self.list(key, values)
      proc do |val, par|
        val = val.to_s if val.is_a?(Symbol)
        val = val.split(',') if val.is_a?(String)
        if val.is_a?(Array) && !val.empty?
          par[key] = (values & val).join(',')
        end
      end
    end

    def self.string(key, match=nil, keep=0)
      proc do |val, par|
        if val.is_a?(String)
          if match
            m = val.match(match)
            par[key] = m[keep] if m
          else
            par[key] = val
          end
        end
      end
    end

    def self.color(key)
      string(:key, /\A(#|0x)?([0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{4}|[0-9a-f]{3})\Z/i, 2)
    end

    Keys = {
      :crop        => list(:crop, %w{top bottom left right faces}),
      :fmt         => string(:fmt, /\A(jpg|png|jp2)\Z/),
      :q           => range(:q, 0, 100),
      :page        => range(:page, 1, 9999),
      :dpr         => range(:dpr, 0.01, 10.0, false),
      :mark        => proc do |val, par|
                        case val
                        when Hash
                          par[:mark] = val[:url]
                          Keys[:markscale].call(val[:scale], par)
                          Keys[:markalign].call(val[:align], par)
                        when String
                          par[:mark] = val
                        end
                      end,
      :markscale   => range(:markscale, 0, 100),
      :markalign   => list(:markalign, %w{top middle bottom left center right}),
      :bg          => color(:bg),
      :flip        => string(:flip, /\A(hv|vh|h|v)\Z/),
      :rot         => range(:rot, 0, 359),
      :bri         => range(:bri, -100, 100),
      :con         => range(:con, -100, 100),
      :exp         => range(:exp, -100, 100),
      :high        => range(:high, -100, 100),
      :shad        => range(:shad, -100, 100),
      :gam         => range(:gam, -100, 100),
      :vib         => range(:vib, -100, 100),
      :sharp       => range(:sharp, 0, 100),
      :hue         => range(:hue, 0, 359),
      :sat         => range(:sat, -100, 100),
      :sepia       => range(:sepia, 0, 100),
      :nr          => proc do |val, par|
                        case val
                        when Hash
                          Keys[:nrs].call(val[:sharpness], par)
                          val = val[:level]
                        when Array
                          Keys[:nrs].call(val[1], par)
                          val = val[0]
                        when TrueClass
                          val = 20
                        end
                        if val.is_a?(Numeric)
                          if val < 0 then val = 0
                          elsif val > 100 then val = 100
                          end
                          par[:nr] = val.round
                        end
                      end,
      :nrs         => range(:nrs, 0, 100),
      :txt         => proc do |val, par|
                        case val
                        when Hash
                          par[:txt] = val[:content] unless val[:content].blank?
                          par[:txtfont] = Keys[:txtfont].call(val[:font], par)
                          par[:txtsize] = Keys[:txtsize].call(val[:size], par)
                          par[:txtclr] = Keys[:txtclr].call(val[:color], par)
                          par[:txtalign] = Keys[:txtalign].call(val[:align], par)
                          par[:txtclip] = Keys[:txtclip].call(val[:clip], par)
                          par[:txtcliptxt] = Keys[:txtcliptxt].call(val[:clip_text], par)
                          par[:txtpad] = Keys[:txtpad].call(val[:padding], par)
                          par[:txtwidth] = Keys[:txtwidth].call(val[:width], par)
                          par[:txtshad] = Keys[:txtshad].call(val[:shadow], par)
                        when String
                          par[:txt] = val
                        end
                      end,
      :txtfont     => list(:txtfont, %w{serif sans-serif monospace cursive fantasy bold italic}),
      :txtsize     => range(:txtsize, 4, 200),
      :txtclr      => color(:txtclr),
      :txtalign    => list(:txtalign, %w{left center right top middle bottom}),
      :txtclip     => list(:txtclip, %w{start middle end}),
      :txtcliptxt  => string(:txtcliptxt),
      :txtpad      => range(:txtpad, 0, 2048),
      :txtwidth    => range(:txtwidth, 0, 2048),
      :txtshad     => range(:txtshad, 0, 512),

      # aliases
      :format                    => :fmt,
      :quality                   => :q,
      :watermark                 => :mark,
      :watermark_scale           => :markscale,
      :watermark_align           => :markalign,
      :background                => :bg,
      :background_color          => :bg,
      :rotate                    => :rot,
      :brightness                => :bri,
      :contrast                  => :con,
      :exposure                  => :exp,
      :highlight                 => :high,
      :shadow                    => :shad,
      :gamma                     => :gam,
      :vibrance                  => :vib,
      :sharpness                 => :sharp,
      :sharpen                   => :sharp,
      :saturation                => :sat,
      :noise_reduction           => :nr,
      :reduce_noise              => :nr,
      :noise_reduction_sharpness => :nrs,
      :reduce_noise_sharpness    => :nrs,
      :text                      => :txt,
      :text_content              => :txt,
      :text_font                 => :txtfont,
      :text_size                 => :txtsize,
      :text_color                => :txtclr,
      :text_align                => :txtalign,
      :text_clip                 => :txtclip,
      :text_clip_text            => :txtcliptxt,
      :text_padding              => :txtpad,
      :text_width                => :txtwidth,
      :text_shadow               => :txtshad
    }

    def self.parameters(style, processors=nil)
      params = {}

      case style
      when String
        geom = Paperclip::Geometry.parse(style)
      when Array
        geom = Paperclip::Geometry.parse(style[0])
        params[:fmt] = style[1] if style[1]
      when Hash
        geom = Paperclip::Geometry.parse(style[:geometry] || style[:geom])
        processors ||= style[:processors]
        style.each do |key, val|
          type = Keys[key]
          type = Keys[type] if type.is_a?(Symbol)
          if type.respond_to?(:call)
            type.call(val, params)
          end
        end
      end

      if geom
        if geom.width > 0 && geom.height > 0
          params[:w] = geom.width.floor
          params[:h] = geom.height.floor
          case geom.modifier
          when '!' then params[:fit] = 'scale'
          when '#' then params[:fit] = 'crop'
          end
        elsif geom.width > 0
          params[:w] = geom.width.floor
        elsif geom.height > 0
          params[:h] = geom.height.floor
        end
      end

      if processors
        if processors.include?(:face_crop) || processors.include?("face_crop")
          if params[:crop]
            params[:crop] += ",faces" unless params[:crop].include?("faces")
          else
            params[:crop] = "faces"
          end
        end
      end

      params
    end

    def self.query(style, processors)
      query_from_parameters(parameters(style, processors))
    end

    MarkKeys = [:markalign, :markscale]
    TextKeys = [:txtfont, :txtsize, :txtclr, :txtalign, :txtclip, :txtcliptxt, :txtpad, :txtwidth, :txtshad]
    URIEscape = Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")

    def self.query_from_parameters(params)
      has_mark = params.key?(:mark)
      has_txt = params.key?(:txt)
      params.map do |key, val|
        next if !has_mark && MarkKeys.include?(key)
        next if !has_txt && TextKeys.include?(key)
        val = URI.escape(val, URIEscape) if val.is_a?(String)
        "#{key}=#{val}"
      end.compact.join('&')
    end

    attr_reader :parameters, :query

    def initialize(style, processors=nil)
      @parameters = self.class.parameters(style, processors)
      @query = self.class.query_from_parameters(@parameters)
    end

    def query(attachment, options=nil)
      style = options && options[:style]
      if style.nil? || style.empty?
        @query
      else
        params = self.class.parameters(style)
        if params.empty?
          @query
        else
          self.class.query_from_parameters(@parameters.merge(params))
        end
      end
    end
  end
end
