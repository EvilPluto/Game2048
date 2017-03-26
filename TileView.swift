//
//  TileView.swift
//  Game2048
//
//  Created by mac on 16/10/28.
//  Copyright © 2016年 pluto. All rights reserved.
//

import UIKit

class TileView: UIView {
    var label: UILabel
    unowned let delegate : AppearanceProviderProtocol
    var value: Int = 0 {
        didSet {
            self.backgroundColor = delegate.tileColor(value: value)
            self.label.textColor = delegate.numberColor(value: value)
            self.label.text = "\(value)"
        }
    }
    
    init(position: CGPoint, width: CGFloat, value: Int, delegate d: AppearanceProviderProtocol) {
        self.delegate = d
        self.label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: width))
        self.label.textAlignment = .center
        self.label.minimumScaleFactor = 0.5
        self.label.layer.cornerRadius = 6
        self.label.font = UIFont(name: "HelveticaNeue-Blod", size: 15) ?? UIFont.systemFont(ofSize: 15)
        
        super.init(frame: CGRect(x: position.x, y: position.y, width: width, height: width))
        self.layer.cornerRadius = 8
        self.addSubview(self.label)
        
        self.value = value
        self.backgroundColor = delegate.tileColor(value: value)
        self.label.textColor = delegate.numberColor(value: value)
        self.label.text = "\(value)"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
