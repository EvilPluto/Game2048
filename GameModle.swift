//
//  GameModle.swift
//  Game2048
//
//  Created by mac on 16/11/2.
//  Copyright © 2016年 pluto. All rights reserved.
//

import UIKit

class GameModle: NSObject {
    let dimension: Int
    let threshold: Int
    
    var gamebord: SequenceGamebord<TileEnum>
    
    unowned let delegate: GameModelProtocol
    
    var score: Int = 0 {
        didSet {
            delegate.changeScore(score: score)
        }
    }
    
    init(dimension: Int, threshold: Int, delegate: GameModelProtocol) {
        self.dimension = dimension
        self.threshold = threshold
        self.delegate = delegate
        gamebord = SequenceGamebord(demision: self.dimension, initValue: TileEnum.Empty)
        super.init()
    }
    
    func getEmptyPosition() -> [(Int, Int)] {
        var emptyArrays: [(Int, Int)] = []
        for i in 0 ..< dimension {
            for j in 0 ..< dimension {
                if case .Empty = gamebord[i, j] {
                    emptyArrays.append((i, j))
                }
            }
        }
        
        return emptyArrays
    }
    
    func insertRandomPositionTile(value: Int) {
        let emptyArrays = getEmptyPosition()
        if emptyArrays.isEmpty {
            return
        }
        let randomPos = Int(arc4random_uniform(UInt32(emptyArrays.count - 1)))
        let (x, y) = emptyArrays[randomPos]
        gamebord[(x, y)] = TileEnum.Tile(value)
        delegate.insertTile(position: (x, y), value: value)
    }
    
    class func quiescentTileStillQuiescent(inputPosition: Int, outputLength: Int, originalPosition: Int) -> Bool {
        return (inputPosition == outputLength) && (originalPosition == inputPosition)
    }
    
    func queenMove(direction: MoveDirection, completion: (Bool) -> ()) {
        let changed = performMove(direction: direction)
        completion(changed)
    }
    
    func performMove(direction: MoveDirection) -> Bool {
        let getMoveQueen: (Int) -> [(Int, Int)] = { (index: Int) -> [(Int, Int)] in
            var buffer = Array<(Int, Int)>(repeating: (0, 0), count: self.dimension)
            for i in 0 ..< self.dimension {
                switch direction {
                case .UP:
                    buffer[i] = (index, i)
                case .DOWN:
                    buffer[i] = (index, self.dimension - i - 1)
                case .LEFT:
                    buffer[i] = (i, index)
                case .RIGHT:
                    buffer[i] = (self.dimension - 1 - i, index)
                }
            }
            return buffer
        }
        var moveFlag = false
        
        for i in 0 ..< self.dimension {
            let moveQueen = getMoveQueen(i)
            let tiles = moveQueen.map({ (c: (Int, Int)) -> TileEnum in
                let (source, value) = c
                return self.gamebord[source, value]
            })
            let moveOrders = merge(group: tiles)
            moveFlag = moveOrders.count > 0 ? true : moveFlag
            for order in moveOrders {
                switch order {
                case let .SINGLEMOVEORDER(s, d, v, m):
                    let (sx, sy) = moveQueen[s]
                    let (dx, dy) = moveQueen[d]
                    if m {
                        self.score += v
                    }
                    gamebord[sx, sy] = TileEnum.Empty
                    gamebord[dx, dy] = TileEnum.Tile(v)
                    delegate.moveOneTile(from: (sx, sy), to: (dx, dy), value: v)
                case let .DOUBLEMOVEORDER(fs, ts, d, v):
                    let (fsx, fsy) = moveQueen[fs]
                    let (tsx, tsy) = moveQueen[ts]
                    let (dx, dy) = moveQueen[d]
                    self.score += v
                    gamebord[fsx, fsy] = TileEnum.Empty
                    gamebord[tsx, tsy] = TileEnum.Empty
                    gamebord[dx, dy] = TileEnum.Tile(v)
                    delegate.moveTwoTiles(from: (moveQueen[fs], moveQueen[ts]), to: moveQueen[d], value: v)
                }
            }
        }
        return moveFlag
    }
    
    func merge(group: [TileEnum]) -> [MoveOrder] {
        return convert(collapse(condense(group)))
    }
    
    // 去空
    func condense(_ group: [TileEnum]) -> [TileAction] {
        var buffer = [TileAction]()
        for (index, tile) in group.enumerated() {
            switch tile {
            case let .Tile(value) where buffer.count == index:
                buffer.append(TileAction.NOACTION(soucre: index, value: value))
            case let .Tile(value):
                buffer.append(TileAction.MOVE(source: index, value: value))
            default:
                break
            }
        }
        return buffer
    }
    
    // 合并相同
    func collapse(_ group: [TileAction]) -> [TileAction] {
        var tokenBuffer = [TileAction]()
        var skipNext = false
        for (index, token) in group.enumerated() {
            if skipNext {
                skipNext = false
                continue
            }
            switch token {
            case let .NOACTION(s, v)
                where (index < group.count - 1 &&
                    v == group[index + 1].getValue() &&
                    GameModle.quiescentTileStillQuiescent(inputPosition: index, outputLength: tokenBuffer.count, originalPosition: s)):
                let next = group[index + 1]
                let nv = v + next.getValue()
                skipNext = true
                tokenBuffer.append(TileAction.SINGLECOMBINE(source: next.getSource(), value: nv))
            case let t where (index < group.count - 1 && t.getValue() == group[index + 1].getValue()):
                let next = group[index + 1]
                let nv = t.getValue() + next.getValue()
                skipNext = true
                tokenBuffer.append(TileAction.DOUBLECOMBINE(firstSource: t.getSource(), secondSource: next.getSource(), value: nv))
            case let .NOACTION(s, v)
                where !GameModle.quiescentTileStillQuiescent(inputPosition: index, outputLength: tokenBuffer.count, originalPosition: s):
                tokenBuffer.append(TileAction.MOVE(source: s, value: v))
            case let .NOACTION(s, v):
                tokenBuffer.append(TileAction.NOACTION(soucre: s, value: v))
            case let .MOVE(s, v):
                tokenBuffer.append(TileAction.MOVE(source: s, value: v))
            default:
                break
            }
        }
        return tokenBuffer
    }
    
    func convert(_ group: [TileAction]) -> [MoveOrder] {
        var buffer = [MoveOrder]()
        for (index, tileAction) in group.enumerated() {
            switch tileAction {
            case let .MOVE(s, v):
                buffer.append(MoveOrder.SINGLEMOVEORDER(source: s, destination: index, value: v, merged: false))
            case let .SINGLECOMBINE(s, v):
                buffer.append(MoveOrder.SINGLEMOVEORDER(source: s, destination: index, value: v, merged: true))
            case let .DOUBLECOMBINE(s, d, v):
                buffer.append(MoveOrder.DOUBLEMOVEORDER(firstSource: s, secondSource: d, destination: index, value: v))
            default:
                break
            }
        }
        return buffer
    }
    
    func reset() {
        score = 0
        gamebord.setAll(value: .Empty)
    }
    
    func userHasWon() -> (Bool, (Int, Int)?) {
        for i in 0 ..< dimension {
            for j in 0 ..< dimension {
                /*
                if case let .Tile(v) = gamebord[i, j] {
                    if v >= threshold {
                        return (true, (i, j))
                    }
                }
                */
                switch gamebord[i, j] {
                case let .Tile(v) where v >= threshold:
                    return (true, (i, j))
                default:
                    break
                }
            }
        }
        return (false, nil)
    }
    
    func userHasLost() -> Bool {
        guard getEmptyPosition().isEmpty else {
            return false
        }
        
        for i in 0 ..< dimension {
            for j in 0 ..< dimension {
                switch gamebord[i, j] {
                case .Empty:
                    assert(false, "Gamebord reported itself as full, but we still found an empty tile. This is a logic error!")
                case let .Tile(v):
                    if tileBelowHasSameValue((i, j), v) || tileBelowHasSameValue((i, j), v) {
                        return false
                    }
                }
            }
        }
        return true
    }
    
    func tileBelowHasSameValue(_ location: (Int, Int), _ value: Int) -> Bool {
        let (x, y) = location
        guard y != dimension - 1 else {
            return false
        }
        if case let .Tile(v) = gamebord[x, y + 1] {
            return v == value
        }
        return false
    }
    
    func tileToRightHasSameValue(_ location: (Int, Int), _ value: Int) -> Bool {
        let (x, y) = location
        guard x != dimension - 1 else {
            return false
        }
        if case let .Tile(v) = gamebord[x + 1, y] {
            return v == value
        }
        return false
    }
}
