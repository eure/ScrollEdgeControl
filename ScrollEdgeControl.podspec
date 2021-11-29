Pod::Spec.new do |s|

  s.name         = "ScrollEdgeControl"
  s.version      = "1.0.0"
  s.summary      = "Yet another UIRefreshControl"
  s.description  = <<-DESC
  Yet another UIRefreshControl. It's control for edge in scroll view.
                   DESC

  s.homepage     = "http://github.com/eure/ScrollEdgeControl"
  s.license      = "MIT"
  s.author             = { "Muukii" => "hiroshi.kimura@eure.jp", "Matto" => "takuma.matsushita@eure.jp" }
  s.ios.deployment_target = "12.0"
  s.source       = { :git => "https://github.com/eure/ScrollEdgeControl.git", :tag => "#{s.version}" }
  s.dependency "Advance"
  s.default_subspec = "Library"
  s.swift_versions = ["5.4", "5.5"]

  s.subspec "Core" do |ss|
    ss.source_files = "ScrollEdgeControl/Core/**/*.swift"
  end

  s.subspec "Library" do |ss|
    ss.source_files = "ScrollEdgeControl/Library/**/*.swift"
    ss.dependency "ScrollEdgeControl/Core"
  end
end
