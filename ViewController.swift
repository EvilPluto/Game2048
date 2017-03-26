//
//  ViewController.swift
//  Game2048
//
//  Created by mac on 16/10/26.
//  Copyright © 2016年 pluto. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func setupGame(_ sender: AnyObject) {
        let game = NumbertailGameController(demension: 4, threshold: 2048)
        self.present(game, animated: true, completion: nil)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

