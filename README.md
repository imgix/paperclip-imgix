# Paperclip::Imgix

---

**Note:** This project is not actively maintained, and will not work with the latest versions of Paperclip. We instead recommend using our lighter-weight [imgix-rb](https://github.com/imgix/imgix-rb) for building imgix URLs.
---

Add the power, speed, and adaptability of [Imgix](http://www.imgix.com) to your Rails project without changing your code. This plugin is designed to work seamlessly with new or existing projects that use [Paperclip](https://github.com/thoughtbot/paperclip) for image management, but removes the hassle, slowness, and rigidity of ImageMagick. You'll get faster uploads for your users, and when you decide to change your site's design using a different image size, you won't wait ages running `rake paperclip:refresh` on your massive image set.

There is one point to be aware of when developing with this plugin. Because Imgix is a proxy, the source images need to be publicly accessible. In production, this is not an issue, but in development it requires either using the [S3](http://rubydoc.info/gems/paperclip/Paperclip/Storage/S3) storage option, or ensuring your development images can be publicly addressed. We are looking into some solutions for this, but if neither of these options can work for you, do [let us know](https://github.com/zebrafishlabs/paperclip-imgix/issues).

## Installation

Add this line to your application's Gemfile:

    gem 'paperclip-imgix'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paperclip-imgix

## Usage

If you are starting from scratch, follow the [Paperclip's Quick Start](https://github.com/thoughtbot/paperclip#quick-start) to get started. The quick start example will be used as the basis for this usage example. But if you've already got a project you'd like to adapt, the changes should be simple enough to follow along and make similar additions to your own model(s).

The first thing you will need is to setup an [source with Imgix](http://www.imgix.com/docs#sources). For this example, lets assume your source domain name is `paperclip`. Source names are globally unique, so you'll have a different name. Just substitute the name you've chosen for your source.

Starting with this model:

    class User < ActiveRecord::Base
	  has_attached_file :avatar, :styles => { :medium => "300x300>", :thumb => "100x100>" }
    end

Configure Paperclip to use the [S3](http://rubydoc.info/gems/paperclip/Paperclip/Storage/S3) storage type:

    class User < ActiveRecord::Base
	  has_attached_file :avatar, {
	    :styles => { :medium => "300x300>", :thumb => "100x100>" },
	    :storage => :s3,
        :bucket => "paperclip-imgix",
        :s3_credentials => "config/amazon_s3.yml"
	  }
    end

And then add your S3 credentials to `RAILS_ROOT/config/amazon_s3.yml`.

Now, to configure this `User#avatar` field to use Imgix:

    class User < ActiveRecord::Base
	  has_attached_file :avatar, {
	    :styles => { :medium => "300x300>", :thumb => "100x100>" },
	    # other configurations
	    :imgix => {
	        :type => 's3',
	        :domain_name => 'paperclip'
	    }
	  }
    end
    
An S3 Imgix source is not required when storing images in S3. If you are using a different source type or want more information, see how to [configure a Web Folder, Web Proxy, or S3 source](https://github.com/zebrafishlabs/paperclip-imgix/wiki/Configuring-Sources).

Likely you'll want to create separate configurations for development, test, and production. You can do that by adding the keys for each environment:

    class User < ActiveRecord::Base
	  has_attached_file :avatar, {
	    :styles => { :medium => "300x300>", :thumb => "100x100>" },
	    # other configurations
	    :imgix => {
	        :development => {
	          :type => 's3',
	          :domain_name => 'paperclip'
	        },
	        :test => { … },
	        :production => { … }
	    }
	  }
    end

To share configurations with multiple models and to keep all configurations organized, you can put the imgix configuration in a YAML file:

    class User < ActiveRecord::Base
	  has_attached_file :avatar, {
	    :styles => { :medium => "300x300>", :thumb => "100x100>" },
	    # other configurations
	    :imgix => 'config/imgix.yml'
	  }
    end

and in `RAILS_ROOT/config/imgix.yml`:

    development:
      type: s3
	  domain_name: paperclip
	test:
	  # …
	production:
	  # …

And, that's it! Your views don't need to change at all, but they do have some new [super powers](#styles).

## Styles

This plugin piggy-backs on the style declarations already in use with Paperclip. You don't need to change anything to get started, but once you're running on Imgix, you can change the styles as your site evolves.

Often you will have your style defined by a geometry string, such as:

    :styles => { :thumb => "100x100#" }

That will work as is, but you can also use a `Hash` for the style definition:

    :styles => { :thumb => { :geometry => "100x100#" } }

That works using straight-up Paperclip. But, this is where using the Imgix plugin adds tremendous power. For example:

    :styles => {
      :thumb => {
        :geometry => "100x100#",
        :crop => :faces,
        :vibrance => 10,
        :reduce_noise => { :level => 20, :sharpness => 50 }
      }
    }

Now, instead of simply cropping the thumbnail in the center of the image, an area is selected to best fit any faces found in the picture. While you're at it, you can boost the vibrance of the image, and apply some noise reduction.

Because the images are rendered on demand, you are no longer limited to only defining styles in the model. You can combine style declarations in your views:

    <%= image_tag @user.avatar.url(:thumb, :style => { :sepia => 50 }) %>

This will add a 50% sepia toning to the image, in addition to the styles set in the model. By merging the style declaration in the model, you can build up styles from other sources, such as other fields in the model. Adding this style declaration to the model:

    :styles => {
      :medium => {
        :geometry => "300x300>",
        :text => { :font => %w{sans-serif bold}, :size => 36,
                   :color => 'FFF', :shadow => 5 }
      }
    }

in the view, you can:

    <%= image_tag @user.avatar.url(:thumb, :style => { :text => @user.screen_name }) %>

To learn more about what you can do, the [wiki page on Styles](https://github.com/zebrafishlabs/paperclip-imgix/wiki/Styles) includes all the currently supported style options.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
