require 'redmine'

# Tell Zeitwerk to ignore this plugin's lib directory
Redmine::Plugin.register :redmine_app_notifications do
  name 'Redmine App Notifications plugin'
  author 'Michal Vanzura'
  description 'App notifications plugin provides simple in application notifications. It can replace default e-mail notifications.'
  version '7.0.0'
  requires_redmine version_or_higher: '7.0.0'
  url 'https://github.com/MichalVanzura/redmine_app_notifications'
  author_url 'https://github.com/MichalVanzura/redmine_app_notifications'

  menu :top_menu, :app_notifications, { :controller => 'app_notifications', :action => 'index' }, {
  	:caption => :notifications,
  	:last => true,
  	:if => Proc.new { User.current.app_notification },
    :html => {:id => 'notificationsLink'}
  }

  menu :top_menu, :app_notifications_count, { :controller => 'app_notifications', :action => 'index' }, {
    :caption => Proc.new { AppNotification.where(recipient_id: User.current.id, viewed: false).count.to_s },
    :last => true,
    :if => Proc.new { User.current.app_notification && AppNotification.where(recipient_id: User.current.id, viewed: false).count > 0 },
    :html => {:id => 'notification_count'}
  }

  settings :default => {
      'issue_added' => 'on',
      'issue_updated' => 'on',
      'issue_note_added' => 'on',
      'issue_status_updated' => 'on',
      'issue_assigned_to_updated' => 'on',
      'issue_priority_updated' => 'on',
      'faye_server_adress' => 'http://ip_address_or_name_of_your_server:9292/faye'
    }, :partial => 'settings/app_notifications_settings'
end

# Redmine 7: apply the patches DIRECTLY (they no longer self-apply at file bottom;
# the modules autoload via Zeitwerk). AppNotificationsHookListener self-registers on
# eager-load. NOTE: AccountPatch builds an alias_method chain, so the `unless
# included?` guard matters (a double include would re-alias). The Issue/Journal
# patches are ActiveSupport::Concerns (after_create callbacks).
#
# Faye is client-side only (a JS include from the optional `faye_server_adress`
# setting, empty by default) — no Ruby gem, so no Ruby-4.0 gem risk here. refs #108530.
unless MyController.included_modules.include?(AppNotificationsAccountPatch)
  MyController.include(AppNotificationsAccountPatch)
end

unless Issue.included_modules.include?(AppNotificationsIssuesPatch)
  Issue.include(AppNotificationsIssuesPatch)
end

unless Journal.included_modules.include?(AppNotificationsJournalsPatch)
  Journal.include(AppNotificationsJournalsPatch)
end
