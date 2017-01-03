//
//  StackBar.swift
//  CustomViewTest
//
//  Created by GangGongUi on 2016. 11. 30..
//  Copyright © 2016년 com.estsoft. All rights reserved.
//

import UIKit
import QuartzCore

//@IBDesignable
class StackBar: UIView {
    
    @IBInspectable open var stackBarColor: UIColor
    @IBInspectable open var stackBarTopColor: UIColor
    @IBInspectable open var stackMinimumShootingLineColor: UIColor
    @IBInspectable open var maximumTime: CGFloat
    @IBInspectable open var stackTopLineWidth: CGFloat
    
    
    // Coordinates of the baseline indicating the minimum recording time
    private lazy var xOfminimumShootingLine: CGFloat = (self.frame.width / self.maximumTime * 5)
    // Coordinates of the baseline indicating the current recording time
    private var xOfcureentStackCoord: CGFloat = 0
    // Stack that stores coordinates that previously stopped shooting
    private var oldStopCoordHistoryStack = [CGFloat]()
    // A delegate telling the state of the stack bar
    var delegate: StackBarCurrentDelegate?
    
    var isCompleate: Bool = false
    
    
    override init(frame: CGRect) {
        stackBarColor = UIColor.white
        stackBarTopColor = UIColor.red
        stackMinimumShootingLineColor = UIColor.yellow
        maximumTime = 15.0
        stackTopLineWidth = 5.0
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        stackBarColor = UIColor.white
        stackBarTopColor = UIColor.red
        stackMinimumShootingLineColor = UIColor.yellow
        maximumTime = 15.0
        stackTopLineWidth = 2.0
        super.init(coder: aDecoder)
    }
    
    override func draw(_ rect: CGRect) {
        
        let context = UIGraphicsGetCurrentContext()
        
        // Draw a filled stack
        context?.setLineWidth(self.frame.height * 2)
        context?.setStrokeColor(stackBarColor.cgColor)
        context?.move(to: CGPoint(x: 0, y: 0))
        context?.addLine(to: CGPoint(x: xOfcureentStackCoord - stackTopLineWidth, y: 0))
        context?.strokePath()
            
        // Draw a stack top line
        func drawStackTopLine(xOfStackTopCoord: CGFloat) {
            if xOfStackTopCoord > stackTopLineWidth {
                context?.setLineWidth(stackTopLineWidth)
                context?.setStrokeColor(stackBarTopColor.cgColor)
                context?.move(to: CGPoint(x: xOfStackTopCoord - stackTopLineWidth, y: 0))
                context?.addLine(to:
                    CGPoint(x: xOfStackTopCoord - stackTopLineWidth, y: self.frame.height * 2))
                context?.strokePath()
            }
        }
        
        for xOfoldStackTopCoord in oldStopCoordHistoryStack {
            drawStackTopLine(xOfStackTopCoord: xOfoldStackTopCoord)
        }
        drawStackTopLine(xOfStackTopCoord: xOfcureentStackCoord)
        
        // Draw MinimumShootingLine
        if self.xOfcureentStackCoord < self.xOfminimumShootingLine {
            context?.setLineWidth(1.0)
            context?.setStrokeColor(stackMinimumShootingLineColor.cgColor)
            context?.move(to: CGPoint(x: xOfminimumShootingLine, y: 0))
            context?.addLine(
                to: CGPoint(x: xOfminimumShootingLine, y: self.frame.height*2))
            context?.strokePath()
        } else {
        
        }
    }
    

    // Stack stacking starts.
    func startStacking(time: Float64) {
        // Update the stack bar according to the music playback time.
        if self.xOfcureentStackCoord >= self.frame.width - stackTopLineWidth {
            // Call function from delegate when shooting is complete
            if !isCompleate {
                self.delegate?.onStackBarComplete?()
                isCompleate = true
            }
        } else {
            self.setNeedsDisplay()
            self.xOfcureentStackCoord = self.frame.width * CGFloat(time) / 15.0
        }
        
        // Make sure the recording is completed for the minimum recording time
        if self.xOfcureentStackCoord >= self.xOfminimumShootingLine {
            // Pass minimum shooting conditions
            self.delegate?.minimumRecordingtimeComplete?()
        } else {
            self.delegate?.minimumRecordingtimeLess?()
        }
    }
    
    func push() {
        //print("push() \(self.xOfcureentStackCoord)")
        // Current location push
        oldStopCoordHistoryStack.append(self.xOfcureentStackCoord)
    }
    
    
    // Stack stacking stops.
    func stopStacking() {
        //print("stopStacking() \(self.xOfcureentStackCoord)")
        stackBarCoordChangeCall()
    }
    
    // Pop the stack.
    func popStack() {
        guard !oldStopCoordHistoryStack.isEmpty else {
            return
        }
        
        //print("popStack() \(self.xOfcureentStackCoord)    popLast -> \(self.oldStopCoordHistoryStack.last)")
        xOfcureentStackCoord = oldStopCoordHistoryStack.popLast()!
        setNeedsDisplay()
        stackBarCoordChangeCall()
        self.delegate?.onStackBarPop?()
    }
    
    func clearStack() {
        //print("clearStack() \(self.xOfcureentStackCoord)")
        self.xOfcureentStackCoord = 0
        self.oldStopCoordHistoryStack.removeAll()
        self.delegate?.onStackBarCoordChanged(stackCurredCoord: CGPoint(x: xOfcureentStackCoord - stackTopLineWidth / 2, y: self.frame.height), width: self.bounds.width)
        self.setNeedsDisplay()
    }
    
    // Tells the current top position of the stack.
    private func stackBarCoordChangeCall() {
        self.delegate?.onStackBarCoordChanged(stackCurredCoord: CGPoint(x: xOfcureentStackCoord - stackTopLineWidth / 2, y: self.frame.height), width: self.bounds.width)
    }
    
}

@objc protocol StackBarCurrentDelegate {
    func onStackBarCoordChanged(stackCurredCoord: CGPoint, width: CGFloat)
    @objc optional func onStackBarComplete()
    @objc optional func onStackBarPop()
    @objc optional func minimumRecordingtimeComplete()
    @objc optional func minimumRecordingtimeLess()
}


