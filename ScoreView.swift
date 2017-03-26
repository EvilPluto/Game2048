//
//  ScoreView.swift
//  Game2048
//
//  Created by mac on 16/10/28.
//  Copyright © 2016年 pluto. All rights reserved.
//

import UIKit

protocol ScoreProtocol {
    func scoreChanged(newScore s: Int)
}

class ScoreView: UIView, ScoreProtocol {
    var label: UILabel
    var score: Int = 0 {
        didSet {
            label.text = "SCORE: \(score)"
        }
    }
    let defaultFrame = CGRect(x: 0, y: 0, width: 140, height: 40)
    
    init(backgroundColor bgColor: UIColor, textColor tColor: UIColor, font: UIFont) {
        self.label = UILabel(frame: self.defaultFrame)
        self.label.textAlignment = .center
        super.init(frame: self.defaultFrame)
        self.backgroundColor = bgColor
        self.label.textColor = tColor
        self.label.font = font
        self.label.layer.cornerRadius = 6 // 圆角属性
        self.addSubview(self.label)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func scoreChanged(newScore s: Int) {
        self.score = s
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
