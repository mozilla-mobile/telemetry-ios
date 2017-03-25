//
//  ViewController.swift
//  TestApp
//
//  Created by Justin D'Arcangelo on 3/13/17.
//
//

import UIKit
import Telemetry

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let telemetry = Telemetry(storageName: "telemetry")
        telemetry.recordSessionStart()
        telemetry.recordSessionEnd()
        telemetry.queueCorePing()
    }

}

