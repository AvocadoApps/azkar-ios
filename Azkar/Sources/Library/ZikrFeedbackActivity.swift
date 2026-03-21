// Copyright © 2021 Al Jawziyya. All rights reserved. 

import UIKit
import Library

final class ZikrFeedbackActivity: UIActivity {
    
    let prepareAction: Action
    
    init(prepareAction: @escaping Action) {
        self.prepareAction = prepareAction
        super.init()
    }
    
    override var activityTitle: String? {
        L10n.Common.reportProblem
    }
    
    override var activityImage: UIImage? {
        UIImage(systemName: "flag")
    }
    
    override static var activityCategory: UIActivity.Category {
        UIActivity.Category.action
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        prepareAction()
    }
    
}
