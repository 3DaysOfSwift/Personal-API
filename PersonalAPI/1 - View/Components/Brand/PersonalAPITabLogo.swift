import UIKit

/// Render the existing brand artwork at native tab-icon size, removing its generous
/// presentation margins so the fingerprint remains legible in the tab bar.
enum PersonalAPITabLogo {
  static let image: UIImage = {
    guard let source = UIImage(named: "PersonalAPITab"), let cgImage = source.cgImage else {
      return UIImage()
    }
    let crop = CGRect(
      x: CGFloat(cgImage.width) * 0.20,
      y: CGFloat(cgImage.height) * 0.12,
      width: CGFloat(cgImage.width) * 0.58,
      height: CGFloat(cgImage.height) * 0.71)
    guard let cropped = cgImage.cropping(to: crop) else { return source }
    let size = CGSize(width: 25, height: 30)
    return UIGraphicsImageRenderer(size: size).image { _ in
      UIImage(cgImage: cropped).draw(in: CGRect(origin: .zero, size: size))
    }.withRenderingMode(.alwaysOriginal)
  }()
}
