import UIKit

extension UIViewController {
    var topmostPresentedViewController: UIViewController? {
        presentedViewController?.topmostPresentedViewController ?? self
    }
}
