//
//  Utilities.swift
//  Instakilo
//
//  Created by Mark on 1/7/18.
//  Copyright © 2018 Mark. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    // computed property
    var contents: UIViewController {
        // implicit getter
        if let navCon = self as? UINavigationController {
            return navCon.visibleViewController ?? self
        } else {
            return self
        }
    }
	
	func showIndicators() {
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
	}
	
	func hideIndicators() {
		UIApplication.shared.isNetworkActivityIndicatorVisible = false
	}
}

extension UIColor {
    static var background: UIColor {
        return UIColor(red: 242.0/255.0, green: 240.0/255.0, blue: 235.0/255.0, alpha: 1.0)
    }
}

extension Double {
    // MARK: Need to edit
    var timeElapsed: String {
        let elapseSeconds = Int(Date().timeIntervalSince1970 - self / 1000)
        
        let hr = elapseSeconds / 3600
        let days = hr / 24
        let remainder = elapseSeconds - hr * 3600
        let min = remainder / 60
        
        // check days
        if days == 1 {
            return "\(days) DAY AGO"
        } else if days > 1 {
            return "\(days) DAYS AGO"
        }
        
        // check hrs
        if hr == 1 {
            return "\(hr) HOUR AGO"
        } else if hr > 1 {
            return "\(hr) HOURS AGO"
        }
        
        // check minutes
        if min == 1 {
            return "\(min) MINUTE AGO"
        } else if min > 1 {
            return "\(min) MINUTES AGO"
        }
        
        return "JUST NOW"
    }
	
	var readableTime: String {
		let date = Date(timeIntervalSince1970: self)
		let formatter = DateFormatter()
		formatter.dateFormat = "MMM d, h:mm a"
		return formatter.string(from: date)
	}
}


