# Adds the LogosWidgets WidgetKit extension (home/lock widgets + Live Activity)
# to ios/Runner.xcodeproj. Idempotent: does nothing if the target exists.
require 'xcodeproj'

path = File.expand_path('../ios/Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(path)
exit 0 if project.targets.any? { |t| t.name == 'LogosWidgets' }

runner = project.targets.find { |t| t.name == 'Runner' }
team = runner.build_configurations.first.build_settings['DEVELOPMENT_TEAM'] ||
       project.targets.flat_map(&:build_configurations).map { |c| c.build_settings['DEVELOPMENT_TEAM'] }.compact.first

ext = project.new_target(:app_extension, 'LogosWidgets', :ios, '16.2', nil, :swift)

widgets_group = project.main_group.new_group('LogosWidgets', 'LogosWidgets')
shared_group = project.main_group.new_group('Shared', 'Shared')
flutter_group = project.main_group.groups.find { |g| g.display_name == 'Flutter' }
runner_group = project.main_group.groups.find { |g| g.display_name == 'Runner' }

%w[LogosWidgetsBundle.swift LogosWidgets.swift LogosLiveActivity.swift LogosStyle.swift].each do |f|
  ext.add_file_references([widgets_group.new_reference(f)])
end
%w[Caprasimo-Regular.ttf Figtree-Bold.ttf Figtree-Regular.ttf].each do |f|
  ext.add_resources([widgets_group.new_reference(f)])
end
widgets_group.new_reference('Info.plist')
widgets_group.new_reference('LogosWidgets.entitlements')

shared = shared_group.new_reference('LogosActivityAttributes.swift')
ext.add_file_references([shared])
runner.add_file_references([shared])
runner.add_file_references([runner_group.new_reference('LiveActivityChannel.swift')])
runner_group.new_reference('Runner.entitlements')

xcconfig = flutter_group.new_reference('Flutter/WidgetExtension.xcconfig') # Flutter group has no path

ext.build_configurations.each do |c|
  c.base_configuration_reference = xcconfig
  s = c.build_settings
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.logosinme.logosMobileApp.LogosWidgets'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['INFOPLIST_FILE'] = 'LogosWidgets/Info.plist'
  s['GENERATE_INFOPLIST_FILE'] = 'NO'
  s['CODE_SIGN_ENTITLEMENTS'] = 'LogosWidgets/LogosWidgets.entitlements'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['DEVELOPMENT_TEAM'] = team if team
  s['SWIFT_VERSION'] = '5.0'
  s['IPHONEOS_DEPLOYMENT_TARGET'] = '16.2'
  s['TARGETED_DEVICE_FAMILY'] = '1,2'
  s['SKIP_INSTALL'] = 'YES'
  s['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks', '@executable_path/../../Frameworks']
  s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
  s['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = ''
end

runner.build_configurations.each do |c|
  c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

runner.add_dependency(ext)
embed = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
embed.name = 'Embed Foundation Extensions'
embed.symbol_dst_subfolder_spec = :plug_ins
bf = embed.add_file_reference(ext.product_reference)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
# Before Flutter's run-script phases to avoid an Xcode build cycle.
resources_index = runner.build_phases.index { |p| p.isa == 'PBXResourcesBuildPhase' }
runner.build_phases.insert(resources_index + 1, embed)

project.save
puts 'LogosWidgets target added'
