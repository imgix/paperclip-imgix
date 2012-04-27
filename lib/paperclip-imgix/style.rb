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
        val = val.split(',') if val.is_a?(String)
        if val.is_a?(Array) && !val.empty?
          par[key] = (values & val).join(',')
        end
      end
    end

    def self.string(key, match=nil)
      proc do |val, par|
        if val.is_a?(String)
          par[key] = val if match.nil? || val.match(match)
        end
      end
    end

    Keys = {
      :crop      => list(:crop, %w{top bottom left right faces}),
      :fmt       => string(:fmt, /\A(jpg|png|jp2)\Z/),
      :q         => range(:q, 0, 100),
      :page      => range(:page, 1, 9999),
      :dpr       => range(:dpr, 0.01, 10.0, false),
      :mark      => proc do |val, par|
                      case val
                      when Hash
                        par[:mark] = val[:url]
                        Keys[:markscale].call(val[:scale], par)
                        Keys[:markalign].call(val[:align], par)
                      when String
                        par[:mark] = val
                      end
                    end,
      :markscale => range(:markscale, 0, 100),
      :markalign => list(:markalign, %w{top middle bottom left center right}),
      :bg        => string(:bg, /\A(#|0x)?([0-9a-f]{8}|[0-9a-f]{6}|[0-9a-f]{4}|[0-9a-f]{3})\Z/i),
      :flip      => string(:flip, /\A(hv|vh|h|v)\Z/),
      :rot       => range(:rot, 0, 359),
      :bri       => range(:bri, -100, 100),
      :con       => range(:con, -100, 100),
      :exp       => range(:exp, -100, 100),
      :high      => range(:high, -100, 100),
      :shad      => range(:shad, -100, 100),
      :gam       => range(:gam, -100, 100),
      :vib       => range(:vib, -100, 100),
      :sharp     => range(:sharp, 0, 100),
      :hue       => range(:hue, 0, 359),
      :sat       => range(:sat, -100, 100),
      :sepia     => range(:sepia, 0, 100),
      :nr        => proc do |val, par|
                      case val
                      when Hash
                        val = val[:level]
                        Keys[:nrs].call(val[:sharpness], par)
                      when Array
                        val = val[0]
                        Keys[:nrs].call(val[1], par)
                      end
                      if val.is_a?(Numeric)
                        if val < 0 then val = 0
                        elsif val > 100 then val = 100
                        end
                        par[:nr] = val.round
                      end
                    end,
      :nrs       => range(:nrs, 0, 100),

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
      :saturation                => :sat,
      :noise_reduction           => :nr,
      :reduce_noise              => :nr,
      :noise_reduction_sharpness => :nrs,
      :reduce_noise_sharpness    => :nrs
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

    attr_reader :parameters, :query

    def initialize(style, processors=nil)
      @parameters = self.class.parameters(style, processors)
      @query = @parameters.to_query
    end

    def query(attachment, options=nil)
      if options.nil? || options.empty?
        @query
      else
        params = self.class.parameters(options)
        if params.empty?
          @query
        else
          @parameters.merge(params).to_query
        end
      end
    end
  end
end
