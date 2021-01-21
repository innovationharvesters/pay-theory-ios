#
# Be sure to run `pod lib lint PayTheory.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PayTheory'
  s.version          = '0.2.4'
  s.summary          = 'Framework to include PayTheory transactions in your App.'
  s.swift_version    = '5.3'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This pod allows you to incoporate PayTheory payments into your app. Includes a PayTheory class you initialize with your API Key, text fields for capturing card and buyer information, and a button to initalize the transacion. The PayTheory object includes a function to confirm or cancel the transaction once it has been initialized.
                       DESC

  s.homepage         = 'https://github.com/pay-theory/pay-theory-ios'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Pay Theory' => 'support@paytheory.com' }
  s.source           = { :git => 'https://github.com/pay-theory/pay-theory-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '14.0'

  s.source_files = 'PayTheory/Classes/**/*'
  
  # s.resource_bundles = {
  #   'PayTheory' => ['PayTheory/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Alamofire', '~> 5.2'
end
