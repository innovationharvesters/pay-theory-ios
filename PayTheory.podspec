Pod::Spec.new do |s|
  s.name         = "PayTheory"
  s.version      = "0.2.17-lab.1"  # can be any version string
  s.summary      = "Framework to include PayTheory transactions in your App. (Custom branch)"
  s.description  = <<-DESC
    This pod allows you to incorporate PayTheory payments into your app.
    Includes a PayTheory class you initialize with your API Key, text fields
    for capturing card and buyer info, and a button to initialize the transaction.
    (This version references the machone-paytheorylab branch in our custom fork.)
  DESC

  s.homepage     = "https://github.com/innovationharvesters/pay-theory-ios"
  s.license      = { :type => "MIT" }
  s.authors      = { "Pay Theory (Fork by Innovation Harvesters Inc)" => "support@paytheory.com" }

  s.source       = {
    :git => "https://github.com/innovationharvesters/pay-theory-ios.git",
    :branch => "machone-paytheorylab"
  }

  s.platform     = :ios, "15.1"
  s.swift_versions = "5.7"
  s.swift_version  = "5.7"

  s.source_files  = "Sources/pay-theory-ios/**/*"

  s.dependencies  = {
    "Alamofire" => ["~> 5.2"],
    "Sodium"    => ["~> 0.9.1"]
  }
end

