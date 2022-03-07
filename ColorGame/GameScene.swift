//
//  GameScene.swift
//  ColorGame
//
//  Created by Noah Glaser on 2/25/22.
//

import SpriteKit
import GameplayKit

enum Enemies: Int {
    case small
    case medium
    case large
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var tracksArray: [SKSpriteNode]? = [SKSpriteNode]()
    
    var player: SKSpriteNode?
    var target: SKSpriteNode?
    
    var currentTrack = 0
    var movingToTrack = false
    
    let moveSound = SKAction.playSoundFileNamed("move.wav", waitForCompletion: false)
    var backgroundNoise: SKAudioNode!
    
    var timeLabel: SKLabelNode!
    var scoreLabel: SKLabelNode!
    
    var pauseBtn: SKSpriteNode!
    
    // MARK: HUD
    
    var currentScore: Int = 0 {
        didSet {
            self.scoreLabel.text = "SCORE: \(currentScore)"
            GameHandler.sharedInstance.score = currentScore
        }
    }
    
    var remainingTime: TimeInterval = 3 {
        didSet {
            self.timeLabel.text = "TIME: \(Int(remainingTime))"
        }
    }

    let trackVelocities = [180, 200, 250]
    
    var directionArray = [Bool]()
    var velocityArray = [Int]()
    
    let playerCategory: UInt32 = 0x1 << 0
    let enemyCategory: UInt32 = 0x1 << 1
    let targetCategroy: UInt32 = 0x1 << 2
    let powerPowerUpCategory: UInt32 = 0x1 << 3
    
    func setupTracks() {
        for i in 0 ... 8 {
            if let track = self.childNode(withName: "\(i)") as? SKSpriteNode {
                tracksArray?.append(track)
            }
        }
    }
    
    func createHud() {
        timeLabel = self.childNode(withName: "time") as? SKLabelNode
        scoreLabel = self.childNode(withName: "score") as? SKLabelNode
        pauseBtn = self.childNode(withName: "pause") as? SKSpriteNode
        
        
        remainingTime = 10
        currentScore = 0
    }
    
    func launchGameTimer() {
        let timeAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run {
                self.remainingTime -= 1
            },
            SKAction.wait(forDuration: 1)
        ]))
        timeLabel.run(timeAction)
    }
    
    override func didMove(to view: SKView) {
        setupTracks()
        
        createHud()
        
        launchGameTimer()
                
        createPlayer()
        
        createTarget()
        
        if let musicURL = Bundle.main.url(forResource: "background", withExtension: "wav") {
            backgroundNoise = SKAudioNode(url: musicURL)
            addChild(backgroundNoise)
            
        }
        
        self.physicsWorld.contactDelegate = self
        
        if let numberOfTracks = tracksArray?.count {
            for _ in 0 ... numberOfTracks {
                let randomNumberForVelocity = GKRandomSource.sharedRandom().nextInt(upperBound: 3)
                velocityArray.append(trackVelocities[randomNumberForVelocity])
                directionArray.append(GKRandomSource.sharedRandom().nextBool())
            }
        }
        
        self.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.run {
                [weak self] in
                self?.spawnEnemies()
            },
            SKAction.wait(forDuration: 2)
        ])))
    }
    
    
    func moveToNextTrack() {
        player?.removeAllActions()
        movingToTrack = true
        
        
        guard let nextTrack = tracksArray?.first(where: {
            Int($0.name ?? "") == currentTrack + 1
        }) else {
            
            movingToTrack = false
            return
            
        }
        
        if let player = self.player {
            let moveAction = SKAction.move(to: CGPoint(x: nextTrack.position.x, y: player.position.y), duration: 0.2)
            
            let up = directionArray[currentTrack + 1]
            
            player.run(moveAction) {
                [weak self] in
                self?.movingToTrack = false
                
                if self?.currentTrack != 8 {
                    self?.player?.physicsBody?.velocity = up ? CGVector(dx: 0, dy: self?.velocityArray[self?.currentTrack ?? 0] ?? 0) :
                    CGVector(dx: 0, dy:  -(self?.velocityArray[self!.currentTrack ] ?? 0))
                } else {
                    self?.player?.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                }
                
                    
            }
            currentTrack += 1
            self.run(moveSound)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let node = self.nodes(at: location).first(where: { $0 is SKSpriteNode && ["right", "up", "down", "pause"].contains($0.name) })
            
            if node?.name == "right" {
                if currentTrack < 8 {
                    moveToNextTrack()
                }
                
            } else if node?.name == "up" {
                moveVertically(up: true)
            } else if node?.name == "down" {
                moveVertically(up: false)
            } else if node?.name == "pause" {
                print("WORKED")
                guard let scene = self.scene else { fatalError("no scene")}
                if scene.isPaused {
                    scene.isPaused = false
                } else {
                    scene.isPaused = true
                }
            }
        }

    
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !movingToTrack {
            player?.removeAllActions()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        player?.removeAllActions()

    }
    
    func movePlayToStart() {
        if let player = self.player {
            player.removeFromParent()
            self.player = nil
            self.createPlayer()
            self.currentTrack = 0
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if let player = self.player {
            if player.position.y > self.size.height || player.position.y < 0 {
                movePlayToStart()
            }
        }
        
        if remainingTime <= 5 {
            timeLabel.fontColor = .red
        }
        
        if remainingTime <= 0 {
            gameOver()
        }
    }
    
    func moveVertically(up: Bool) {
        if up {
            let moveAction = SKAction.moveBy(x: 0, y: 3, duration: 0.01)
            let repeatAction = SKAction.repeatForever(moveAction)
            player?.run(repeatAction)
        } else {
            let moveAction = SKAction.moveBy(x: 0, y: -3, duration: 0.01)
            let repeatAction = SKAction.repeatForever(moveAction)
            player?.run(repeatAction)

        }
    }
    
    func createPlayer() {
        player = SKSpriteNode(imageNamed: "player")
        player?.physicsBody = SKPhysicsBody(circleOfRadius: player!.size.width / 2)
        player?.physicsBody?.linearDamping = 0 // simulates airflow and will slow down
        player?.physicsBody?.categoryBitMask = playerCategory
        player?.physicsBody?.collisionBitMask = 0
        player?.physicsBody?.contactTestBitMask = enemyCategory | targetCategroy | powerPowerUpCategory
        
        
        guard let playerPosition = tracksArray?.first?.position.x else {
            return
        }
        
        player?.position = CGPoint(x: playerPosition, y: self.size.height / 2)
        addChild(player!)
        
        let pulse = SKEmitterNode(fileNamed: "pulse")!
        player?.addChild(pulse)
        pulse.position = CGPoint(x: 0, y: 0)
    }
    
    func createTarget() {
        target  = self.childNode(withName: "target") as? SKSpriteNode
        target?.physicsBody = SKPhysicsBody(circleOfRadius: target!.size.width / 2)
        target?.physicsBody?.categoryBitMask = targetCategroy
        target?.physicsBody?.collisionBitMask = 0
    }
    
    func createEnemy(type: Enemies, for track: Int) -> SKShapeNode {
        let enemySprite = SKShapeNode()
        enemySprite.name = "ENEMY"
        
        guard let selectedTrack = tracksArray?[track] else { fatalError("No track found for index: \(track)") }
        
        switch type {
        case .small:
            enemySprite.path = CGPath(roundedRect: CGRect(x: -10, y: 0, width: 20, height: 70), cornerWidth: 8, cornerHeight: 8, transform: nil)
            enemySprite.fillColor = UIColor.init(red: 0.4431, green: 0.5529, blue: 0.7451, alpha: 1)
        case .medium:
            enemySprite.path = CGPath(roundedRect: CGRect(x: -10, y: 0, width: 20, height: 100), cornerWidth: 8, cornerHeight: 8, transform: nil)
            enemySprite.fillColor = UIColor.init(red: 0.7804, green: 0.4039, blue: 0.4039, alpha: 1)
        case .large:
            enemySprite.path = CGPath(roundedRect: CGRect(x: -10, y: 0, width: 20, height: 130), cornerWidth: 8, cornerHeight: 8, transform: nil)
            enemySprite.fillColor = UIColor.init(red: 0.7804, green: 0.6392, blue: 0.4039, alpha: 1)
        }
        
        let up = directionArray[track]
        
        
        enemySprite.position.x = selectedTrack.position.x
        enemySprite.position.y = up ? -130 : self.size.height + 130
        

        
        enemySprite.physicsBody = SKPhysicsBody(edgeLoopFrom: enemySprite.path!)
        enemySprite.physicsBody?.categoryBitMask = enemyCategory
        enemySprite.physicsBody?.velocity = up ? CGVector(dx: 0, dy: velocityArray[track]) : CGVector(dx: 0, dy: -velocityArray[track])
        
        
        return enemySprite
    }
    
    func spawnEnemies() {
        
        var randomTrackNumber = 0
        let createPowerUp = GKRandomSource.sharedRandom().nextBool()
        
        if createPowerUp {
            randomTrackNumber = GKRandomSource.sharedRandom().nextInt(upperBound: 6) + 1
            let powerUpObject = self.createPowerUp(forTrack: randomTrackNumber)
            self.addChild(powerUpObject)
            
        }
        
        for i in 1 ... 7 {
            
            if randomTrackNumber == i {
                continue
            }
            
            let randomEnemyType = Enemies(rawValue: GKRandomSource.sharedRandom().nextInt(upperBound: 3))!
             let newEnemy = createEnemy(type: randomEnemyType, for: i)
             self.addChild(newEnemy)
        }
        
        self.enumerateChildNodes(withName: "ENEMY") { (node:SKNode, nil) in
            if node.position.y < -150 || node.position.y > self.size.height + 150 {
                node.removeFromParent()
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var playerBody: SKPhysicsBody
        var otherBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            playerBody = contact.bodyA
            otherBody = contact.bodyB
        } else {
            playerBody = contact.bodyB
            otherBody = contact.bodyA
        }
        
        if playerBody.categoryBitMask == playerCategory  && otherBody.categoryBitMask == enemyCategory {
            self.run(SKAction.playSoundFileNamed("fail.wav", waitForCompletion: true))
            movePlayToStart()
        } else if playerBody.categoryBitMask == playerCategory &&
                    otherBody.categoryBitMask == targetCategroy {
            nextLevel(playerPhysicsBody: playerBody)
        } else if playerBody.categoryBitMask == playerCategory &&
                    otherBody.categoryBitMask == powerPowerUpCategory {
            self.run(SKAction.playSoundFileNamed("powerUp.wav", waitForCompletion: true))
            otherBody.node?.removeFromParent()
            remainingTime += 5
        }
    }
    
    
    func nextLevel(playerPhysicsBody: SKPhysicsBody) {
        self.currentScore += 1
        self.run(SKAction.playSoundFileNamed("levelUp.wav", waitForCompletion: true))
        let emitter = SKEmitterNode(fileNamed: "fireworks.sks")!

        playerPhysicsBody.node?.addChild(emitter)
        self.run(SKAction.wait(forDuration: 0.5)) {
            [weak self] in
            emitter.removeFromParent()
            self?.movePlayToStart()
        }
    }

    func createPowerUp(forTrack track: Int) -> SKSpriteNode {
        let powerUpSprite = SKSpriteNode(imageNamed: "powerUp")
        powerUpSprite.name = "ENEMY"
        powerUpSprite.physicsBody = SKPhysicsBody(circleOfRadius: powerUpSprite.size.width / 2)
        powerUpSprite.physicsBody?.linearDamping = 0
        powerUpSprite.physicsBody?.categoryBitMask = powerPowerUpCategory
        powerUpSprite.physicsBody?.collisionBitMask = 0
        
        let up = directionArray[track]
        
        guard let powerUpXPosition = tracksArray?[track].position.x else { fatalError("no track") }
        powerUpSprite.position.x = powerUpXPosition
        powerUpSprite.position.y = up ? -130 : self.size.height + 130
        
        powerUpSprite.physicsBody?.velocity = up ? CGVector(dx: 0, dy: velocityArray[track]) :
        CGVector(dx: 0, dy: -velocityArray[track])
        
        return powerUpSprite
        
        
    }
    
    func gameOver() {
        GameHandler.sharedInstance.saveGameStats()
        self.run(SKAction.playSoundFileNamed("levelCompleted.wv", waitForCompletion: true))
        let transition = SKTransition.fade(withDuration: 1)
        
        
        if let gameOverScene = SKScene(fileNamed: "GameOverScene") {
            gameOverScene.scaleMode = .aspectFit
            self.view?.presentScene(gameOverScene, transition: transition)
        }
    }
    
}
