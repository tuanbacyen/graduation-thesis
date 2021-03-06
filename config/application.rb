require_relative 'boot'
require 'carrierwave'
require 'carrierwave/orm/activerecord'

require 'rails/all'
require "roo"
require 'pdfkit'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module GraduationThesis
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2
    config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]
    config.i18n.available_locales = [:en, :vi]
    config.i18n.default_locale = :en
    config.assets.paths << Rails.root.join("vendors", "assets")
    config.assets.precompile << /\.(?:svg|eot|woff|ttf)$/
    config.time_zone = Settings.time_zone
    config.assets.initialize_on_precompile = false

    config.middleware.use PDFKit::Middleware, print_media_type: true
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
