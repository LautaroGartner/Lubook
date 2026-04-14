require "active_support/core_ext/integer/time"

Rails.application.configure do
config.after_initialize do
    Bullet.enable        = true
    Bullet.alert         = false
    Bullet.bullet_logger = true
    Bullet.console       = true
    Bullet.rails_logger  = true
    Bullet.add_footer    = true

    # Fragment caching causes false positives for "unused eager loading" —
    # the associations are needed on cache miss, Bullet can't see cache hits.
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Post", association: :likes
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Post", association: :comments
    Bullet.add_safelist type: :unused_eager_loading, class_name: "ActiveStorage::Attachment", association: :blob
  end

  config.enable_reloading = true

  config.eager_load = false

  config.consider_all_requests_local = true

  config.server_timing = true

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
    config.public_file_server.headers = { "cache-control" => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false
  end

  config.cache_store = :memory_store

  config.active_storage.service = :local

  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.perform_caching = false

  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.perform_deliveries = true
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  config.active_support.deprecation = :log

  config.active_record.migration_error = :page_load

  config.active_record.verbose_query_logs = true

  config.active_record.query_log_tags_enabled = true

  config.active_job.verbose_enqueue_logs = true

  config.action_dispatch.verbose_redirect_logs = true

  config.assets.quiet = true

  config.action_view.annotate_rendered_view_with_filenames = true

  config.action_controller.raise_on_missing_callback_actions = true
end
