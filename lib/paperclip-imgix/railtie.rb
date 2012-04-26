require 'paperclip-imgix'

module Paperclip::Imgix
  require 'rails'
  class Railtie < Rails::Railtie
    initializer "paperclip-imgix.insert_into_active_record" do
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(Paperclip::Imgix::ClassMethods)
      end
    end
  end
end
