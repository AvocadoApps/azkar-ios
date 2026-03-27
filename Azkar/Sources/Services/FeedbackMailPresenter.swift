import UIKit
import MessageUI

final class FeedbackMailPresenter {

    private let delegate = MailComposeDelegate()

    func present(from viewController: UIViewController) {
        guard MFMailComposeViewController.canSendMail() else {
            UIApplication.shared.open(URL(string: "https://t.me/jawziyya_feedback")!)
            return
        }

        let mailComposerViewController = MFMailComposeViewController()
        mailComposerViewController.setToRecipients(["azkar.app@pm.me"])
        mailComposerViewController.mailComposeDelegate = delegate
        viewController.present(mailComposerViewController, animated: true)
    }
}

private final class MailComposeDelegate: NSObject, MFMailComposeViewControllerDelegate {

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }
}
