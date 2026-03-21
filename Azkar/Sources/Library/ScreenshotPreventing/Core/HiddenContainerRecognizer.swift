import UIKit

class HiddenContainerRecognizer {

    enum Error: Swift.Error {
        case noTextFieldFound
        case unsupportedOSVersion(version: Float)
    }

    func getHiddenContainer(from textField: UITextField) throws -> UIView {
        // iOS 15 uses _UITextLayoutCanvasView
        if let containerView = textField.subviews.first(where: {
            type(of: $0).description() == "_UITextLayoutCanvasView"
        }) {
            return containerView
        }

        // iOS 17 uses _UITextLayoutFragmentView
        if let containerView = textField.subviews.first(where: {
            type(of: $0).description().contains("TextLayoutFragmentView")
        }) {
            return containerView
        }

        // iOS 18+ uses _UITextFieldCanvasView
        if let containerView = textField.subviews.first(where: {
            type(of: $0).description().contains("CanvasView")
        }) {
            return containerView
        }

        // Check if there's any suitable subview
        if let containerView = textField.subviews.first(where: {
            let typeName = type(of: $0).description()
            return typeName.hasPrefix("_UI") && (
                typeName.contains("Text") ||
                typeName.contains("Canvas") ||
                typeName.contains("Layout")
            )
        }) {
            return containerView
        }

        // If no suitable subview found, throw an error
        let currentIOSVersion = (UIDevice.current.systemVersion as NSString).floatValue
        throw Error.unsupportedOSVersion(version: currentIOSVersion)
    }
}
