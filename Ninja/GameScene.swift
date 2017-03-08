//
//  GameScene.swift
//  Ninja
//
//  Created by 李旻 on 2017/3/1.
//  Copyright © 2017年 里民. All rights reserved.
//

import SpriteKit
import GameplayKit

// operation overloading

func + (left: CGPoint, right: CGPoint) -> CGPoint{
    return CGPoint(x:left.x + right.x, y: left.y + right.y);
}
func - (left: CGPoint, right: CGPoint) -> CGPoint{
    return CGPoint(x: left.x - right.x, y: left.y - right.y);
}
func * (left :CGPoint, scalar: CGFloat) -> CGPoint{
    return CGPoint(x: left.x * scalar, y: left.y * scalar);
}
func / (left: CGPoint, scalar: CGFloat) -> CGPoint{
    return CGPoint(x: left.x / scalar, y: left.y / scalar);
}

#if !(arch(x86_64) || arch(arm64))
func sqrt(a: CGFloat) -> CGFloat{
    return CGFloat(sqrt(Float(a)));
}
    
#endif

extension CGPoint{
    func length() -> CGFloat{
        return sqrt(x*x + y*y);
    }
    
    func normalized() -> CGPoint{
        return self / length();
    }
}


// physics Category config
struct PhysicsCategory{
    static let None : UInt32 = 0;
    static let All : UInt32 = UInt32.max;
    static let Monster : UInt32 = 0b1;
    static let Projectile : UInt32 = 0b01;
}




class GameScene: SKScene, SKPhysicsContactDelegate{
    
    let player = SKSpriteNode(imageNamed: "player");
    
    let scoreLabel = SKLabelNode(fontNamed: "Cuckoo");
    
    var numScore = 0;

    
    override func didMove(to view: SKView) {
        
        backgroundColor = SKColor.green;
        physicsWorld.gravity = CGVector.zero;
        physicsWorld.contactDelegate = self;
        
        // score
        scoreLabel.text = String(format: "%02d", numScore);
        scoreLabel.fontSize = 40;
        scoreLabel.fontColor =  SKColor.white;
        scoreLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.9);
        addChild(scoreLabel);
        
        
        // player
        player.position = CGPoint(x: size.width*0.1, y: size.height * 0.5);
        addChild(player);
        
        // spawn ghost
        run(SKAction.repeatForever(
            SKAction.sequence([SKAction.run(addMonster),
                               SKAction.wait(forDuration: 1.0)])
        ));
        
        
        
        // add music
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-acc.caf");
        backgroundMusic.autoplayLooped = true;
        addChild(backgroundMusic);
        
        
    }
    
    
    
    func monsterRandom() -> CGFloat{
        //print("random : \(CGFloat(Float(arc4random()) / 0xffffffff))")
        // get random integer and divided by 32 bit
        return CGFloat(Float(arc4random()) / 0xffffffff);
    }
    
    func monsterRandom(min: CGFloat, max: CGFloat) -> CGFloat{
        // range to get random
        return monsterRandom() * (max - min) + min ;
    }
    
    
    func addMonster(){
        
        let monster = SKSpriteNode(imageNamed: "monster");
        
        let actualY = monsterRandom(min: monster.size.height/2, max: size.height - monster.size.height/2);
        
        monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY);
        
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size);
        monster.physicsBody?.isDynamic = true;
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster;
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile;
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None;
        
        
        addChild(monster);
        
        /***** action bla bla bla******/
        
        let actualDuration = monsterRandom(min: CGFloat(2.0), max: CGFloat(4.0));
        
        let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration));
        
        let actionMoveDone = SKAction.removeFromParent();
        
        // lose Action
        let loseAction = SKAction.run(){
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5);
            let gameOverScene = DeadScene(size: self.size, won: false, score: self.numScore);
            self.view?.presentScene(gameOverScene, transition: reveal);
        }
        
        // ~~~~~~~~~~~~~~~
        
        monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]));
    }
    
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // choose one of the touches to work with
        guard let touch = touches.first else{
            return;
        }
        
        let touchLocation = touch.location(in: self);
        
        // set up initial location of projectile
        // create sk node
        let projectile = SKSpriteNode(imageNamed: "projectile");
        
        // physical body
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2);
        projectile.physicsBody?.isDynamic = true;
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile;
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster;
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None;
        projectile.physicsBody?.usesPreciseCollisionDetection = true;
        
        projectile.position = player.position;
        // determin offset of location to projectile
        let offset = touchLocation - projectile.position;
        
        // if user touch player back , it would not shoot
        if(offset.x<0){
            return;
        }
        addChild(projectile);
        
        let direction = offset.normalized();
        
        let shootAmount = direction * 1000;
        
        let realDest = shootAmount + projectile.position;
        
        
        // action
        let actionMove = SKAction.move(to: realDest, duration: 2.0);
        let actionMoveDone = SKAction.removeFromParent();
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]));
        
        
        // music
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false));
        
    }
    
    func projectileDidCollideWithMonster(m_projectile: SKSpriteNode, m_monster: SKSpriteNode){
        numScore += 1;
        scoreLabel.text = String(format: "%02d", numScore);
        print("hit");
        m_projectile.removeFromParent();
        m_monster.removeFromParent();
        
    }
    
    
    /* Monster : UInt32 = 0b1;
       Projectile : UInt32 = 0b01; */
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody;
        var secondBody: SKPhysicsBody;
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            
            firstBody = contact.bodyA;  // m
            secondBody = contact.bodyB; // p
        }
        else{
            firstBody = contact.bodyB;  //m
            secondBody = contact.bodyA; //p
        }
        
        // 有點多餘？
        if((firstBody.categoryBitMask & PhysicsCategory.Monster != 0) && (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)){
            
            if let mon = firstBody.node as? SKSpriteNode, let proj = secondBody.node as? SKSpriteNode{
                
                projectileDidCollideWithMonster(m_projectile: proj, m_monster: mon);
                
            }
            
        }
        
    }
    
    
    
    
    
    
}
