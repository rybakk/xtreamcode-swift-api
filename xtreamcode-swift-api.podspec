Pod::Spec.new do |s|
  s.name             = "XtreamcodeSwiftAPI"
  s.version          = "1.1.0"
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
  s.homepage         = "https://github.com/your-org/xtreamcode-swift-api"
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { "Xtreamcode Swift API Contributors" => "noreply@example.com" }
  s.source           = { :git => "https://github.com/your-org/xtreamcode-swift-api.git", :tag => "v#{s.version}" }
  s.swift_versions   = ["5.10", "6.0"]
  s.documentation_url = "https://your-org.github.io/xtreamcode-swift-api/"

  s.ios.deployment_target  = "14.0"
  s.osx.deployment_target  = "12.0"
  s.tvos.deployment_target = "15.0"

  s.source_files     = "Sources/**/*.swift"
  s.requires_arc     = true

  s.dependency "Alamofire", "~> 5.10"

  s.frameworks = "Foundation"
  s.ios.frameworks = "UIKit"
  s.tvos.frameworks = "UIKit"
  s.osx.frameworks = "AppKit"
end
