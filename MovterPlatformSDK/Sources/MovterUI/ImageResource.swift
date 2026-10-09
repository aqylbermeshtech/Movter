// swiftlint:disable all
// swiftformat:disable all

#if os(macOS)
  import AppKit
#elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// MARK: - Asset Catalogs

public enum ImageAsset {
  public static let backButton = MovterImage(name: "BackButton")
  public static let backButtonOTP = MovterImage(name: "BackButtonOTP")
  public static let closeButton = MovterImage(name: "closeButton")
  public static let closeButtonreg = MovterImage(name: "closeButtonreg")
  public static let searchIcon = MovterImage(name: "search_icon")
  public static let voiceIcon = MovterImage(name: "voice_icon")
  public static let chevron = MovterImage(name: "chevron")
  public static let globe = MovterImage(name: "globe")
  public static let google = MovterImage(name: "Google")
  public static let avatarPlaceholderNotionType = MovterImage(name: "avatar_placeholder_notion_type")
  public static let heart = MovterImage(name: "heart")
  public static let settings = MovterImage(name: "settings")
  public static let share = MovterImage(name: "share")
  public static let check = MovterImage(name: "check")
  public static let bell = MovterImage(name: "bell")
  public static let clock = MovterImage(name: "clock")
  public static let calendar = MovterImage(name: "calendar")
}

// MARK: - Implementation Details

public struct MovterImage {
  public let name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
  public typealias Image = UIImage
  #endif

  public var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS) || os(visionOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let image = bundle.image(forResource: NSImage.Name(name))
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
  public var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}


#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, visionOS 1.0, *)
public extension SwiftUI.Image {
  init(asset: MovterImage) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: MovterImage, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: MovterImage) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// MARK: - Bundle Token

private final class BundleToken {
  static let bundle: Bundle = {
    return Bundle.main
  }()
}

// swiftformat:enable all
// swiftlint:enable all
