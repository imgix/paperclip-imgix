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

    COLOR_EXP = /\A(#|0x)?([0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{4}|[0-9a-f]{3})\Z/i

    def self.color(key)
      string(:key, COLOR_EXP, 2)
    end

    Keys = {
      # resize
      :crop        => list(:crop, %w{top bottom left right faces}),
      :dpr         => range(:dpr, 0.01, 8.0, false),
      :rot         => range(:rot, 0, 359),
      :or          => list(:or, [0,1,2,3,4,5,6,7,8,9,90,180,270]),
      :flip        => string(:flip, /\A(hv|vh|h|v)\Z/),
      :rect        => string(:rect, /\A\d+,\d+,\d+,\d+\Z/),

      # format
      :fmt         => string(:fmt, /\A(jpg|png|jp2)\Z/),
      :q           => range(:q, 0, 100),

      # auto
      :auto        => proc do |val, par|
                        case val
                        when TrueClass
                          par[:auto] = "true"
                        else
                          val = val.to_s if val.is_a?(Symbol)
                          val = val.split(',') if val.is_a?(String)
                          if val.is_a?(Array) && !val.empty?
                            par[key] = (%w{format enhance redeye} & val).join(',')
                          end
                        end
                      end,

      # enhance
      :hue         => range(:hue, 0, 359),
      :sat         => range(:sat, -100, 100),
      :bri         => range(:bri, -100, 100),
      :con         => range(:con, -100, 100),
      :exp         => range(:exp, -100, 100),
      :high        => range(:high, -100, 100),
      :shad        => range(:shad, -100, 100),
      :gam         => range(:gam, -100, 100),
      :vib         => range(:vib, -100, 100),
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
      :sharp       => range(:sharp, 0, 100),

      # stylize
      :blur        => range(:blur, 0, 1000),
      :mono        => color(:mono),
      :sepia       => range(:sepia, 0, 100),
      :htn         => range(:htn, 0, 100),
      :px          => range(:px, 0, 100),

      # mask
      :mask        => proc do |val, par|
                        if val == :ellipse
                          par[:mask] = "ellipse"
                        elsif val.is_a? String
                          par[:mask] = val
                        end
                      end,

      # watermark
      :mark        => proc do |val, par|
                        case val
                        when Hash
                          par[:mark] = val[:url]
                          Keys[:markw].call(val[:w] || val[:width], par)
                          Keys[:markh].call(val[:h] || val[:height], par)
                          Keys[:markfit].call(val[:fit], par)
                          Keys[:markpad].call(val[:pad], par)
                          Keys[:markscale].call(val[:scale], par)
                          Keys[:markalign].call(val[:align], par)
                        when String, URL
                          par[:mark] = val.to_s
                        end
                      end,
      :markw       => range(:markw, 0, 2048, false),
      :markh       => range(:markh, 0, 2048, false),
      :markfit     => list(:markfit, %w{clip cl crop cr fill clamp min max scale}),
      :markpad     => range(:markpad, 0, 2048),
      :markscale   => range(:markscale, 0, 100),
      :markalign   => list(:markalign, %w{top middle bottom left center right}),

      # text
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

      # general
      :border      => proc do |val, par|
                        case val
                        when Hash
                          par[:border] = "#{val[:width] || val[:w] || 4},#{val[:color]}"
                        when COLOR_EXP
                          par[:border] = "4,#{val}"
                        end
                      end,
      :bg          => color(:bg),
      :page        => range(:page, 1, 9999),

      # aliases
      :background                => :bg,
      :background_color          => :bg,
      :brightness                => :bri,
      :contrast                  => :con,
      :exposure                  => :exp,
      :format                    => :fmt,
      :gamma                     => :gam,
      :highlight                 => :high,
      :noise_reduction           => :nr,
      :noise_reduction_sharpness => :nrs,
      :orient                    => :or,
      :quality                   => :q,
      :reduce_noise              => :nr,
      :reduce_noise_sharpness    => :nrs,
      :rotate                    => :rot,
      :saturation                => :sat,
      :shadow                    => :shad,
      :sharpen                   => :sharp,
      :sharpness                 => :sharp,
      :text                      => :txt,
      :text_align                => :txtalign,
      :text_clip                 => :txtclip,
      :text_clip_text            => :txtcliptxt,
      :text_color                => :txtclr,
      :text_content              => :txt,
      :text_font                 => :txtfont,
      :text_padding              => :txtpad,
      :text_shadow               => :txtshad,
      :text_size                 => :txtsize,
      :text_width                => :txtwidth,
      :vibrance                  => :vib,
      :watermark                 => :mark,
      :watermark_align           => :markalign,
      :watermark_scale           => :markscale,
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
