# Be sure to restart your server when you modify this file.

# ApplicationController.renderer.defaults.merge!(
#   http_host: 'example.org',
#   https: false
# )

unless Rails.env.test?
  @@MVESTS ||= MvestsLookupJob.perform_later
end
