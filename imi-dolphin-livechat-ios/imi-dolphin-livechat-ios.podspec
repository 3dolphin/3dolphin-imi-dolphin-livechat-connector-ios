
Pod::Spec.new do |spec|


  spec.name         = "imi-dolphin-livechat-ios"
  spec.version      = "2.0.3"
  spec.summary      = "Description of livechat connector by 3dolphins"

  spec.description  = "dolphin livechat connector is a library which help user to build chat application easy using Stompclient library"

  spec.homepage     = "https://github.com/3dolphin/3dolphin-imi-dolphin-livechat-connector-ios"

  spec.license      = "MIT"

  spec.author       = { "3dolphin" => "dolphininmo@gmail.com" }
  
  
  spec.swift_version = "5.0"
  spec.platform     = :ios, "11.0"
  spec.ios.deployment_target  = '11.0'
 
  spec.source       = { :git => "https://github.com/3dolphin/3dolphin-imi-dolphin-livechat-connector-ios.git", :tag => spec.version.to_s }

  spec.source_files  = '**/Sources/*.swift'

  spec.dependency "StompClientLib"
  spec.dependency "CryptoSwift", '~> 1.3.8'


end
