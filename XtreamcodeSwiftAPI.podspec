Pod::Spec.new do |s|
  s.name             = "XtreamcodeSwiftAPI"
  s.version          = "1.2.2"
  s.summary          = "Modern Swift SDK for Xtream Codes IPTV platforms"
  s.description      = <<-DESC
A comprehensive Swift SDK for Xtream Codes IPTV platforms featuring:
• Complete authentication and account management
• Live TV streaming with EPG and catch-up support
• VOD (Video on Demand) catalog with detailed metadata
• Series/TV shows with seasons and episodes
• Unified search across all content types
• Intelligent hybrid caching (memory + disk)
• Modern async/await API with Combine and closure adapters
• Full support for iOS, macOS, and tvOS platforms
DESC
  s.homepage          = "https://github.com/rybakk/xtreamcode-swift-api"
  s.license           = { :type => "MIT", :file => "LICENSE" }
  s.author            = { "Xtreamcode Swift API Contributors" => "noreply@example.com" }
  s.source            = { :git => "https://github.com/rybakk/xtreamcode-swift-api.git", :tag => "v#{s.version}" }
  s.swift_versions    = ["5.10", "6.0"]
  s.documentation_url = "https://rybakk.github.io/xtreamcode-swift-api/"

  s.ios.deployment_target  = "14.0"
  s.osx.deployment_target  = "12.0"
  s.tvos.deployment_target = "15.0"

  s.dependency "Alamofire", "~> 5.10"

  # Single target with module aliases so the existing imports (`XtreamModels`, `XtreamClient`, `XtreamServices`)
  # resolve to the unified CocoaPods module (`XtreamcodeSwiftAPI`).
  s.source_files = "Sources/**/*.swift"
end
