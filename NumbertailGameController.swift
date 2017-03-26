//
//  NumbertailGameController.swift
//  Game2048
//
//  Created by mac on 16/10/26.
//  Copyright © 2016年 pluto. All rights reserved.
//

import UIKit

protocol GameModelProtocol: class {
    func changeScore(score: Int)
    func insertTile(position: (Int, Int), value: Int)
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int)
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int )
}

class NumbertailGameController: UIViewController, GameModelProtocol {
    
    var demension: Int // the blocks on every row and column
    var threshold: Int // the highest grades
    
    var bord: GamebordView?
    
    var scoreV: ScoreView?
    
    var gameModle: GameModle?
    

    let boardWidth: CGFloat = 300.0// game block width
    let thinPadding: CGFloat = 3.0 // width between blocks
    let viewPadding: CGFloat = 10.0 // padding between game block and title
    let verticalViewOffset: CGFloat = 0.0 // for init
    
    init(demension d: Int, threshold t: Int) {
        self.demension = d < 2 ? 2 : d;
        self.threshold = t < 8 ? 8 : t;
        super.init(nibName: nil, bundle: nil)
        self.gameModle = GameModle(dimension: d, threshold: t, delegate: self)
        view.backgroundColor = UIColor(red: 0xE6/255, green: 0xE2/255, blue: 0xD4/255, alpha: 1)
        setupSwipeController()
    }
    
    func setupSwipeController() {
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(NumbertailGameController.upCommand(_ :)))
        upSwipe.numberOfTouchesRequired = 1
        upSwipe.direction = UISwipeGestureRecognizerDirection.up
        view.addGestureRecognizer(upSwipe)
        
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(NumbertailGameController.downCommand(_ :)))
        downSwipe.numberOfTouchesRequired = 1
        downSwipe.direction = UISwipeGestureRecognizerDirection.down
        view.addGestureRecognizer(downSwipe)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(NumbertailGameController.leftCommand(_ :)))
        leftSwipe.numberOfTouchesRequired = 1
        leftSwipe.direction = UISwipeGestureRecognizerDirection.left
        view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(NumbertailGameController.rightCommand(_ :)))
        rightSwipe.numberOfTouchesRequired = 1
        rightSwipe.direction = UISwipeGestureRecognizerDirection.right
        view.addGestureRecognizer(rightSwipe)
    }
    
    func upCommand(_ r: UIGestureRecognizer) {
        let m = gameModle!
        m.queenMove(direction: .UP, completion: { (changed: Bool) -> () in
            if changed {
                self.followUP()
            }
        })
    }
    
    func downCommand(_ r: UIGestureRecognizer) {
        let m = gameModle!
        m.queenMove(direction: .DOWN, completion: { (changed: Bool) -> () in
            if changed {
                self.followUP()
            }
        })
    }
    
    func leftCommand(_ r: UIGestureRecognizer) {
        let m = gameModle!
        m.queenMove(direction: .LEFT, completion: { (changed: Bool) -> () in
            if changed {
                self.followUP()
            }
        })
    }
    
    func rightCommand(_ r: UIGestureRecognizer) {
        let m = gameModle!
        m.queenMove(direction: .RIGHT, completion: { (changed: Bool) -> () in
            if changed {
                self.followUP()
            }
        })
    }
    
    func followUP() {
        assert(gameModle != nil)
        let m = gameModle!
        let (userWon, _) = m.userHasWon()
        if userWon {
            let winAlertView = UIAlertController(title: "结果", message: "你赢了", preferredStyle: .alert)
            let resetAction = UIAlertAction(title: "重置", style: .default, handler: { (u: UIAlertAction) -> () in
                self.reset()
            })
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            winAlertView.addAction(resetAction)
            winAlertView.addAction(cancelAction)
            self.present(winAlertView, animated: true, completion: nil)
            return
        }
        
        let randomVal = Int(arc4random_uniform(10))
        m.insertRandomPositionTile(value: randomVal <= 2 ? 4 : 2)
        
        if m.userHasLost() {
            NSLog("You Lost ---------")
            let lostAlertView = UIAlertController(title: "结果", message: "你输了", preferredStyle: .alert)
            let resetAction = UIAlertAction(title: "重置", style: .default, handler: { (u: UIAlertAction) -> () in
                self.reset()
            })
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            lostAlertView.addAction(resetAction)
            lostAlertView.addAction(cancelAction)
            self.present(lostAlertView, animated: true, completion: nil)
        }
    }
    
    func reset() {
        assert(bord != nil && gameModle != nil)
        let b = bord!
        let m = gameModle!
        b.reset()
        m.reset()
        m.insertRandomPositionTile(value: 2)
        m.insertRandomPositionTile(value: 2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGame()
        // Do any additional setup after loading the view.
    }

    func setupGame() {
        let viewWidth = view.bounds.size.width
        let viewHeight = view.bounds.size.height
        
        func xposition2Center(view v: UIView) -> CGFloat {
            let vWidth = v.bounds.size.width
            return (viewWidth - vWidth) / 2
        }
        
        func yposition2Center(order: Int, views: [UIView]) -> CGFloat {
            assert(views.count > 0)
            let totalViewHeight = CGFloat(views.count - 1) * viewPadding + views.map({
                $0.bounds.size.height
            }).reduce(verticalViewOffset, {$0 + $1})
            let firstY = (viewHeight - totalViewHeight) / 2
            
            var acc: CGFloat = 0
            for i in 0 ..< order {
                acc += viewPadding + views[i].bounds.size.height
            }
            
            print("acc: \(acc)")
            return acc + firstY
        }
        
        let width = (boardWidth - thinPadding * CGFloat(demension + 1)) / CGFloat(demension)
        
        let scoreView = ScoreView(
            backgroundColor: UIColor(red: 0xA2/255, green: 0x94/255, blue: 0x5E/255, alpha: 1),
            textColor: UIColor(red: 0xF3/255, green: 0xF1/255, blue: 0x1A/255, alpha: 1),
            font: UIFont(name: "HelveticaNeue-Blod", size: 16.0) ?? UIFont.systemFont(ofSize: 16.0)
        )
        
        let gamebord = GamebordView(
            demesion: demension,
            titleWidth: width,
            titlePadding: thinPadding,
            backgroundColor: UIColor(red: 0x90/255, green: 0x8D/255, blue: 0x80/255, alpha: 1),
            foregroundColor: UIColor(red: 0xF9/255, green: 0xF9/255, blue: 0xE3/255, alpha: 0.5)
        )
        
        let views = [scoreView, gamebord]
        
        var f = gamebord.frame
        f.origin.x = xposition2Center(view: gamebord)
        f.origin.y = yposition2Center(order: 1, views: views)
        print("x:\(f.origin.x) y:\(f.origin.y)")
        gamebord.frame = f
        view.addSubview(gamebord)
        bord = gamebord
        
        //gamebord.insertTile(pos: (3, 1), value: 2)
        //gamebord.insertTile(pos: (1, 3), value: 2)
        
        var f1 = scoreView.frame
        f1.origin.x = xposition2Center(view: scoreView)
        f1.origin.y = yposition2Center(order: 0, views: views)
        scoreView.frame = f1
        scoreView.scoreChanged(newScore: 0)
        view.addSubview(scoreView)
        scoreV = scoreView
        
        assert(gameModle != nil)
        let modle = gameModle!
        modle.insertRandomPositionTile(value: 2)
        modle.insertRandomPositionTile(value: 2)
    }
    
    func changeScore(score: Int) {
        assert(scoreV != nil)
        let s = scoreV!
        s.scoreChanged(newScore: score)
    }
    
    func insertTile(position pos: (Int, Int), value: Int) {
        assert(bord != nil)
        let b = bord!
        b.insertTile(pos: pos, value: value)
    }
    
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int) {
        assert(bord != nil)
        let b = bord!
        b.moveOneTiles(from: from, to: to, value: value)
    }
    
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
        assert(bord != nil)
        let b = bord!
        b.moveTwoTiles(from: from, to: to, value: value)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
