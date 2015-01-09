//
//  GameScene.swift
//  Dr.StrangeLove
//
//  Created by prashanth on 1/2/15.
//  Copyright (c) 2015 prashanth. All rights reserved.
//

import SpriteKit

import AVFoundation


func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

struct physicsCategory{
    
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let myPlane   : UInt32 = 0b1       // 1
    static let enemyPlane: UInt32 = 0b10      // 2
    static let bullet    : UInt32 = 0004      // 4
    
}


var backgroundMusicPlayer: AVAudioPlayer!

func playBackgroundMusic(filename: String) {
    let url = NSBundle.mainBundle().URLForResource(
        filename, withExtension: nil)
    if (url == nil) {
        println("Could not find file: \(filename)")
        return
    }
    
    var error: NSError? = nil
    backgroundMusicPlayer =
        AVAudioPlayer(contentsOfURL: url, error: &error)
    if backgroundMusicPlayer == nil {
        println("Could not create audio player: \(error!)")
        return
    }
    
    backgroundMusicPlayer.numberOfLoops = -1
    backgroundMusicPlayer.prepareToPlay()
    backgroundMusicPlayer.play()
}

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    let myplane = SKSpriteNode(imageNamed: "enemy")
    var enemyPlanes = 0
 
    let missCount = SKLabelNode(fontNamed: "Chalkduster")

    
    
    
    override func didMoveToView(view: SKView) {
        
        setBackground()
        addMyPlane()
        
        physicsWorld.gravity=CGVectorMake(0,0)
        physicsWorld.contactDelegate=self
        
        runAction(SKAction.repeatActionForever(
            SKAction.sequence([
                SKAction.runBlock(addEnemyPlanes),
                SKAction.waitForDuration(1.0)
                ])
            ))
        
    }
    
    func setBackground(){
        
        playBackgroundMusic("background-music-aac.caf")
        
        let background = SKSpriteNode(imageNamed: "airPlanesBackground")
        background.position=CGPointMake(CGRectGetMidX(self.frame),CGRectGetMidY(self.frame))
        addChild(background)
        
        missCount.text = String(enemyPlanes)
        missCount.fontSize = 40
        missCount.fontColor = SKColor.blackColor()
        missCount.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(missCount)
        
    }
    
    func addMyPlane(){
        myplane.xScale = 0.5
        myplane.yScale = 0.5
        myplane.position = CGPoint(x: size.width * 0.5, y: myplane.size.height*2.0)
        
        addChild(myplane)
        
        myplane.physicsBody = SKPhysicsBody(rectangleOfSize: myplane.size)
        myplane.physicsBody?.dynamic=true
        myplane.physicsBody?.categoryBitMask=physicsCategory.myPlane
        myplane.physicsBody?.contactTestBitMask=physicsCategory.enemyPlane
        myplane.physicsBody?.collisionBitMask=physicsCategory.enemyPlane
        
    }
    
    func addEnemyPlanes(){
        
        if(enemyPlanes > 5)
        {
            enemyPlanes = 0
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameResult(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        else{
            missCount.text = String(enemyPlanes)
            enemyPlanes++
        }
        
        let enemyPlane = SKSpriteNode(imageNamed: "PLANE 8 N")

        // random location where we start this enemy
        
        enemyPlane.xScale = 0.3
        enemyPlane.yScale = 0.3
        
        let actualX = random(min: enemyPlane.size.width * 4.0, max: size.width - enemyPlane.size.width * 4.0)
        
        enemyPlane.position = CGPoint(x: actualX, y:size.height)
        
        addChild(enemyPlane)
        
        enemyPlane.physicsBody = SKPhysicsBody(rectangleOfSize: enemyPlane.size)
        enemyPlane.physicsBody?.dynamic=true
        enemyPlane.physicsBody?.categoryBitMask=physicsCategory.enemyPlane
        enemyPlane.physicsBody?.contactTestBitMask=physicsCategory.bullet
        enemyPlane.physicsBody?.collisionBitMask=physicsCategory.None
        
        
        
        let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
        let actionMove = SKAction.moveTo(CGPoint(x:actualX,y: -enemyPlane.size.height), duration: NSTimeInterval(actualDuration))
        let actionMoveDone = SKAction.removeFromParent();
        
        enemyPlane.runAction(SKAction.sequence([actionMove,actionMoveDone]))
        
        
    }
    
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(#min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        
        runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
        let touch = touches.anyObject() as UITouch
        let touchLocation = touch.locationInNode(self)
        
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.xScale=0.2
        bullet.yScale=0.2
        bullet.position = myplane.position
        
        bullet.physicsBody = SKPhysicsBody(rectangleOfSize: bullet.size)
        bullet.physicsBody?.dynamic=true
        bullet.physicsBody?.categoryBitMask = physicsCategory.bullet
        bullet.physicsBody?.contactTestBitMask = physicsCategory.enemyPlane
        bullet.physicsBody?.collisionBitMask = physicsCategory.None
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        
        // 3 - Determine offset of locatilon to projectile
        let offset = touchLocation - bullet.position
        
        // 4 - Bail out if you are shooting down or backwards
        if (offset.y < 0) { return }
        
        // 5 - OK to add now - you've double checked position
        addChild(bullet)
        
        // 6 - Get the direction of where to shoot
        let direction = offset.normalized()
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // 8 - Add the shoot amount to the current position
        let realDest = shootAmount + bullet.position
        
        // 9 - Create the actions
        let actionMove = SKAction.moveTo(realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        bullet.runAction(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        let sum = contact.bodyA.categoryBitMask+contact.bodyB.categoryBitMask
        
        if(sum == 6){
            contact.bodyA.node?.removeFromParent()
            contact.bodyB.node?.removeFromParent()
            enemyPlanes--
        }
        else if(sum==3)
        {
            let reveal = SKTransition.flipHorizontalWithDuration(0.5)
            let gameOverScene = GameResult(size: self.size, won: false)
            self.view?.presentScene(gameOverScene, transition: reveal)
        }
        
    }
    
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
