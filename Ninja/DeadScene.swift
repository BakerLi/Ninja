//
//  DeadScene.swift
//  Ninja
//
//  Created by 李旻 on 2017/3/8.
//  Copyright © 2017年 里民. All rights reserved.
//

//import Foundation
import SpriteKit;



class DeadScene : SKScene{
    
    init(size: CGSize, won: Bool, score : Int) {
        super.init(size: size);
        
        backgroundColor = SKColor.black;
        
        let message = won ? "sp4 !" : "you suck !" ;
        
        // label
        let label = SKLabelNode(fontNamed: "Cuckoo");
        label.fontColor = SKColor.yellow;
        label.text = message ;
        label.fontSize = 40;
        label.position = CGPoint(x: size.width/2, y: size.height/2);
        addChild(label);
        
        // label score
        let scoreLabel = SKLabelNode(fontNamed: "Cuckoo");
        scoreLabel.fontColor = SKColor.red;
        scoreLabel.text = " kill : \(score)";
        scoreLabel.fontSize = 20;
        scoreLabel.position = CGPoint(x: size.width/2, y: size.height/3);
        addChild(scoreLabel);

        
        // Action
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run {
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5);
                let scene = GameScene(size: size);
                self.view?.presentScene(scene, transition: reveal);
            }
            ]));
        
    }
    
    // becuase you override init
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
