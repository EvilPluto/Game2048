//
//  GamebordView.swift
//  Game2048
//
//  Created by mac on 16/10/27.
//  Copyright © 2016年 pluto. All rights reserved.
//

import UIKit

class GamebordView: UIView {
    var demension: Int // blocks on every row(column)
    var titleWidth: CGFloat // width of every block
    var titlePadding: CGFloat // padding between blocks
    
    let provider = AppearanceProvider()
    
    let tilePopStartScale: CGFloat = 0.1
    let tilePopMaxScale: CGFloat = 1.1
    let tilePopDelay: TimeInterval = 0.05
    let tileExpandTime: TimeInterval = 0.18
    let tileContractTime: TimeInterval = 0.08
    
    let tileMergeStartScale: CGFloat = 1.0
    let tileMergeExpandTime: TimeInterval = 0.08
    let tileMergeContractTime: TimeInterval = 0.08
    
    let perSquareSlideDuration: TimeInterval = 0.08
    
    var tiles: Dictionary<IndexPath, TileView>
    
    init(demesion d: Int, titleWidth width: CGFloat, titlePadding padding: CGFloat, backgroundColor: UIColor, foregroundColor: UIColor) {
        self.demension = d
        self.titleWidth = width
        self.titlePadding = padding
        tiles = Dictionary()
        let totalWidth = titlePadding + CGFloat(demension) * (self.titlePadding + self.titleWidth)
        super.init(frame: CGRect(x: 0, y: 0, width: totalWidth, height: totalWidth))
        self.backgroundColor = backgroundColor
        self.setColor(backgroundColor: backgroundColor, foregroundColor: foregroundColor)
    }
    
    func setColor(backgroundColor bgcolor: UIColor, foregroundColor forecolor: UIColor) {
        self.backgroundColor = bgcolor
        var xCursor = titlePadding
        var yCursor: CGFloat
        
        for _ in 0 ..< demension {
            yCursor = titlePadding
            for _ in 0 ..< demension {
                let titleFrame = UIView(frame: CGRect(x: xCursor, y: yCursor, width: titleWidth, height: titleWidth))
                titleFrame.backgroundColor = forecolor
                titleFrame.layer.cornerRadius = 8
                self.addSubview(titleFrame)
                yCursor += titlePadding + titleWidth
            }
            xCursor += titlePadding + titleWidth
        }
    }
    
    func positionIsValied(position: (Int, Int)) -> Bool {
        let (x, y) = position
        return x >= 0 && x < self.demension && y >= 0 && y < self.demension
    }
    
    func insertTile(pos: (Int, Int), value: Int) {
        assert(self.positionIsValied(position: pos))
        let (row, col) = pos
        
        let x = self.titlePadding + CGFloat(row) * (self.titlePadding + self.titleWidth)
        let y = self.titlePadding + CGFloat(col) * (self.titlePadding + self.titleWidth)
        let tileView = TileView(position: CGPoint(x: x, y: y), width: titleWidth, value: value, delegate: provider)
        self.addSubview(tileView)
        self.bringSubview(toFront: tileView)
        
        tiles[IndexPath(row: row, section: col)] = tileView
        
        UIView.animate(
            withDuration: self.tileExpandTime,
            delay: self.tilePopDelay,
            options: .transitionCurlDown,
            animations: {
                tileView.layer.setAffineTransform(CGAffineTransform(scaleX: self.tilePopMaxScale, y: self.tilePopMaxScale))
            },
            completion: {
                finished in
                UIView.animate(withDuration: self.tileContractTime, animations: {
                    () -> Void in
                    tileView.layer.setAffineTransform(CGAffineTransform.identity)
                })
            }
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func moveOneTiles(from: (Int, Int), to: (Int, Int), value: Int) {
        let (fx, fy) = from
        let (tx, ty) = to
        let fromKey = IndexPath(row: fx, section: fy)
        let toKey = IndexPath(row: tx, section: ty)
        guard let tile = tiles[fromKey] else {
            assert(false, "not exists tile")
        }
        let endTile = tiles[toKey]
        
        var changeFrame = tile.frame
        changeFrame.origin.x = titlePadding + CGFloat(tx) * (titlePadding + titleWidth)
        changeFrame.origin.y = titlePadding + CGFloat(ty) * (titlePadding + titleWidth)
        
        tiles.removeValue(forKey: fromKey)
        tiles[toKey] = tile
        
        let shouldPop = endTile != nil
        UIView.animate(withDuration: perSquareSlideDuration,
                       delay: 0.0,
                       options: .beginFromCurrentState,
                       animations: {
                        tile.frame = changeFrame
        },
                       completion: { (finished: Bool) -> Void in
                        tile.value = value
                        endTile?.removeFromSuperview()
                        if !shouldPop || !finished {
                            return
                        }
                        tile.layer.setAffineTransform(CGAffineTransform(scaleX: self.tileMergeStartScale, y: self.tileMergeStartScale))
                        UIView.animate(withDuration: self.tileMergeExpandTime,
                                       animations: {
                                        tile.layer.setAffineTransform(CGAffineTransform(scaleX: self.tilePopMaxScale, y: self.tilePopMaxScale))
                        },
                                       completion: { finished in
                                        UIView.animate(withDuration: self.tileMergeContractTime, animations: {
                                            tile.layer.setAffineTransform(CGAffineTransform.identity)
                                        })
                        })
        })
    }
    
    func moveTwoTiles(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
        assert(positionIsValied(position: (from.0)) && positionIsValied(position: (from.1)) && positionIsValied(position: to))
        let (fromRowA, fromColA) = from.0
        let (fromRowB, fromColB) = from.1
        let (toRow, toCol) = to
        let fromKeyA = IndexPath(row: fromRowA, section: fromColA)
        let fromKeyB = IndexPath(row: fromRowB, section: fromColB)
        let toKey = IndexPath(row: toRow, section: toCol)
        
        guard let tileA = tiles[fromKeyA] else {
            assert(false, "placeholder error")
        }
        
        guard let tileB = tiles[fromKeyB] else {
            assert(false, "placeholder error")
        }
        
        var finalFrame = tileA.frame
        finalFrame.origin.x = titlePadding + CGFloat(toRow) * (titleWidth + titlePadding)
        finalFrame.origin.y = titlePadding + CGFloat(toCol) * (titleWidth + titlePadding)
        
        let oldTile = tiles[toKey]
        oldTile?.removeFromSuperview()
        tiles.removeValue(forKey: fromKeyA)
        tiles.removeValue(forKey: fromKeyB)
        tiles[toKey] = tileA
        
        UIView.animate(withDuration: perSquareSlideDuration,
                       delay: 0.0,
                       options: .beginFromCurrentState,
                       animations: {
                        tileA.frame = finalFrame
                        tileB.frame = finalFrame
        },
                       completion: { finished in
                        tileA.value = value
                        tileB.removeFromSuperview()
                        if !finished {
                            return
                        }
                        tileA.layer.setAffineTransform(CGAffineTransform(scaleX: self.tileMergeStartScale, y: self.tileMergeStartScale))
                        UIView.animate(withDuration: self.tileMergeExpandTime,
                                       animations: {
                                        tileA.layer.setAffineTransform(CGAffineTransform(scaleX: self.tilePopMaxScale, y: self.tilePopMaxScale))
                        },
                                       completion: { finished in
                                        UIView.animate(withDuration: self.tileMergeContractTime, animations: {
                                            tileA.layer.setAffineTransform(CGAffineTransform.identity)
                                        })
                        })
        })
    }
    
    func reset() {
        for (_, tile) in tiles {
            tile.removeFromSuperview()
        }
        tiles.removeAll(keepingCapacity: true)
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
