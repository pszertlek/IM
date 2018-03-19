//
//  ViewController.swift
//  IM
//
//  Created by apple on 2017/12/12.
//  Copyright © 2017年 Pszertlek. All rights reserved.
//

import UIKit
import Foundation
import JavaScriptCore

enum sss: Int {
    case a = 1,b,c,d,e
    case f = 10
}
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        let s = sss.a
        print(s)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func testJs() {
        let jsPath = Bundle.main.path(forResource: "test", ofType: "js")
        let jsContent =  try! NSString.init(contentsOfFile: jsPath!, encoding: String.Encoding.utf8.rawValue)
        let context = JSContext()
        context?.evaluateScript(jsContent as String!)
        let value = context?.evaluateScript("appendString").call(withArguments: ["hello"])
        let value1 = context?.evaluateScript("arr")
        print(value?.toString(),value1?.toArray())
        
    }

}

