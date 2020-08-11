//
//  LollipopViewController.swift
//  Save The Lollipop
//
//  Created by Jintian Wang on 2020/7/7.
//  Copyright © 2020 Jintian Wang. All rights reserved.
//

import UIKit
import AudioToolbox
import AVFoundation
import GoogleMobileAds
import FirebaseAnalytics
import ChameleonFramework

class LollipopViewController: UIViewController, GADRewardedAdDelegate {
  
    @IBOutlet var speakerButton: UIButton!
    @IBOutlet var overlayView: UIView!
    @IBOutlet var succeedLabel: UILabel!
    @IBOutlet var failedLabel: UILabel!
    @IBOutlet var adsNotReadyLabel: UILabel!
    @IBOutlet var adView: UIView!
    @IBOutlet var rewardLabel: UILabel!
    @IBOutlet var adImageView: UIImageView!
    @IBOutlet var yesButton: UIButton!
    @IBOutlet var noButton: UIButton!
    
    @IBOutlet var progressBar: UIProgressView!
    @IBOutlet var idleProgressBar: UIProgressView!
    @IBOutlet var goalLabel: UILabel!
    @IBOutlet var easyLabel: UILabel!
    @IBOutlet var tipLabel: UILabel!
    @IBOutlet var succeedTopLabel: UILabel!
    @IBOutlet var clockLabel: UILabel!
    @IBOutlet var tapToStartLabel: UILabel!
    @IBOutlet var exitButton: UIButton!
    @IBOutlet var bestTimeLabel: UILabel!
    @IBOutlet var topView: UIView!
    
    private var backPlayer: AVAudioPlayer!
    
    fileprivate enum ScreenEdge: Int {
        case top = 0
        case right = 1
        case bottom = 2
        case left = 3
    }
  
    fileprivate enum GameState {
        case ready
        case playing
        case gameOver
    }
  
    fileprivate var isEarned = false
    fileprivate let radius: CGFloat = 10
    fileprivate let playerAnimationDuration = 4.0
    fileprivate let enemySpeed: CGFloat = 60 
    fileprivate let colors = [#colorLiteral(red: 0, green: 1, blue: 0.6969391141, alpha: 1), #colorLiteral(red: 0, green: 1, blue: 0.9403944271, alpha: 1), #colorLiteral(red: 0.9942306064, green: 0.8164629054, blue: 0.3185636885, alpha: 1), #colorLiteral(red: 0, green: 0.0376328557, blue: 1, alpha: 1), #colorLiteral(red: 0.2581393733, green: 1, blue: 0.380602682, alpha: 1), #colorLiteral(red: 0.416045903, green: 1, blue: 0.2837867142, alpha: 1), #colorLiteral(red: 0.9739767191, green: 1, blue: 0.3511664389, alpha: 1), #colorLiteral(red: 1, green: 0.4527270093, blue: 0.2601100501, alpha: 1), #colorLiteral(red: 0.3047611997, green: 0.5936642943, blue: 1, alpha: 1), #colorLiteral(red: 0.3195055882, green: 0.2403193101, blue: 1, alpha: 1), #colorLiteral(red: 1, green: 0.339752952, blue: 0.3431205043, alpha: 1), #colorLiteral(red: 1, green: 0.404501806, blue: 0.4829288422, alpha: 1), #colorLiteral(red: 0.6725139773, green: 0.3649416053, blue: 0.8737249422, alpha: 1), #colorLiteral(red: 1, green: 0.5054037499, blue: 0.8539225226, alpha: 1), #colorLiteral(red: 0.9045985772, green: 0.9045985772, blue: 0.9045985772, alpha: 1), #colorLiteral(red: 0.6477232759, green: 0.700946224, blue: 1, alpha: 1), #colorLiteral(red: 0.4745277209, green: 0.9669233991, blue: 0.9984197021, alpha: 1), #colorLiteral(red: 0.7348475454, green: 0.9999729991, blue: 0.8517441634, alpha: 1), #colorLiteral(red: 1, green: 0.5516949242, blue: 0.6069201352, alpha: 1), #colorLiteral(red: 0.998547256, green: 0, blue: 0.3800080454, alpha: 1)]
  
    fileprivate var playerLabel = UILabel(frame: .zero)
    fileprivate var playerAnimator: UIViewPropertyAnimator?
  
    fileprivate var mushroomBk: UIView?
    fileprivate var mushroom: UIImageView?
    fileprivate var enemyViews = [UIView]()
    fileprivate var enemyAnimators = [UIViewPropertyAnimator]()
    fileprivate var enemyTimer: Timer?
    fileprivate var idleTimer: Timer?
    
    fileprivate var displayLink: CADisplayLink?
    fileprivate var beginTimestamp: TimeInterval = 0

    fileprivate var gameState = GameState.ready
    
    fileprivate var stopAnimatingMush = false
    fileprivate var isViewDisappearing = false
    fileprivate var hasShowedOverlay = false
    
    fileprivate var hasSucceeded = false
    fileprivate var easyTimer: Timer?
    
    fileprivate var elapsedTime: TimeInterval = 0
    
    fileprivate var realTimePassed = 0
    fileprivate var idleTimeLeft = 15 {
        didSet {
            if isFromMission {return}
                
            idleProgressBar.setProgress(Float(idleTimeLeft)/15.0, animated: true)
            if idleTimeLeft <= 0 {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    fileprivate var rewardIndex = -1
    fileprivate var isDoubleSpeed = false
    fileprivate var isHalfSize = false
    fileprivate var isHigherMush = false
    
    var isFromMission = false
    var goal = 10
    
    fileprivate var canTouch = false
    
    private var timesPlayed = 0
    
    private var isPremium = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        isPremium = UserDefaults.standard.bool(forKey: K.isPremium)
        isPremium = true
        
        if isPremium {
            noButton.removeFromSuperview()
        } else {
            K.appDelegate.dotRewardedAd = K.appDelegate.createAndLoadReward(id: K.dotRewardedAdUnitID)
        }
        
        if isFromMission {
            tipLabel.text = (Dot.tips.randomElement() ?? "- Tips: Eat the mushroom to clear the enemies!").localized
        } else {
            tipLabel.text = "Exit will pop up if you win the game or play it for 20 seconds.".localized
        }
        
        idleProgressBar.transform = CGAffineTransform(scaleX: 1, y: 2)
        
        succeedLabel.layer.zPosition = 5
        failedLabel.layer.zPosition = 6
        adView.layer.zPosition = 7
        adsNotReadyLabel.layer.zPosition = 8
        adImageView.layer.zPosition = 9
        
        setupplayerLabel()
        self.playerLabel.alpha = 0
        prepareGame()
    
        goalLabel.text = "\("Goal".localized): \(goal)\("s".localized)"
        
        waitAnimation()
        
        setCorner()
        
        setBackgroundMusic()
    }
    
    func setBackgroundMusic() {
        if UserDefaults.standard.bool(forKey: K.noGameSound) {
            speakerButton.setImage(UIImage(systemName: "speaker.slash.fill"), for: .normal)
        } else {
            speakerButton.setImage(UIImage(systemName: "speaker.1.fill"), for: .normal)
            playBackMusic()
        }
    }
    
    func playBackMusic() {
        let url = Bundle.main.url(forResource: "lollipopBack", withExtension: "mp3")
        if let url = url {
            do {
                backPlayer = try AVAudioPlayer(contentsOf: url)
                backPlayer.play()
                backPlayer.numberOfLoops = -1
            } catch {
            }
        }
    }
    
    @IBAction func speakerTapped(_ sender: UIButton) {
        if UserDefaults.standard.bool(forKey: K.noGameSound) {
            UserDefaults.standard.set(false, forKey: K.noGameSound)
            speakerButton.setImage(UIImage(systemName: "speaker.1.fill"), for: .normal)
            if backPlayer != nil {
                backPlayer.play()
            } else {
                playBackMusic()
            }
        } else {
            UserDefaults.standard.set(true, forKey: K.noGameSound)
            speakerButton.setImage(UIImage(systemName: "speaker.slash.fill"), for: .normal)
            backPlayer.pause()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topView.backgroundColor = UIColor(gradientStyle: .topToBottom, withFrame: topView.bounds, andColors: [#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3),#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        isViewDisappearing = true
        
        if backPlayer != nil {backPlayer.stop()}
        stopEnemyTimer()
        easyTimer?.invalidate()
        easyTimer = nil
        idleTimer?.invalidate()
        idleTimer = nil
    }
    
    func showOverlay() {
        
        if hasShowedOverlay {return}
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.canTouchAndPrepare))

        hasShowedOverlay = true
        isViewDisappearing = true
        
        canTouch = false
        
        UIView.animate(withDuration: 0.2, animations: {
            self.overlayView.alpha = 0.5
        }) { (_) in
            if self.hasSucceeded {
                
                self.overlayView.addGestureRecognizer(tap)
                
                self.succeedLabel.transform = CGAffineTransform(translationX: 0, y: 150)
                UIView.animate(withDuration: 0.2, animations: {
                    self.succeedLabel.alpha = 1
                    self.succeedLabel.transform = CGAffineTransform(translationX: 0, y: -10)
                }) { (_) in
                    self.succeedLabel.transform = CGAffineTransform.identity
                }
            } else {
                
                if self.isPremium {
                    
                    if UserDefaults.standard.bool(forKey: K.isPremium) || Int.random(in: 1...2) == 2 {     // subject to deletion
                        self.overlayView.isUserInteractionEnabled = false
                        self.exitButton.isUserInteractionEnabled = false
                        self.animateAd()
                    } else {                            // subject to deletion
                        self.animateLose(with: self.failedLabel)        //
                        self.overlayView.addGestureRecognizer(tap)      //
                    }                                                      //
                    
                } else {
                
                    if K.appDelegate.dotRewardedAd?.isReady==true && ([1,2,3].randomElement() ?? 2)==2 {
                        self.overlayView.isUserInteractionEnabled = false
                        self.exitButton.isUserInteractionEnabled = false
                        self.animateAd()
                    } else {
                        self.view.isUserInteractionEnabled = false
                        self.animateLose(with: self.failedLabel)
                        self.overlayView.addGestureRecognizer(tap)
                    }
                    
                    if K.appDelegate.dotRewardedAd?.isReady != true {
                        K.appDelegate.dotRewardedAd = K.appDelegate.createAndLoadReward(id: K.dotRewardedAdUnitID)
                    }
                }
            }
        }
    }
    
    @objc func canTouchAndPrepare() {
        hasShowedOverlay = false
        exitButton.isUserInteractionEnabled = true
        overlayView.alpha = 0
        succeedLabel.alpha = 0
        failedLabel.alpha = 0
        adView.alpha = 0
        adImageView.alpha = 0
        adsNotReadyLabel.alpha = 0
        canTouch = true
        prepareGame()
    }
    
    func animateAd() {
        rewardIndex = [0,1,2].randomElement() ?? 0
        if isPremium {
            rewardLabel.text = Dot.premiumRewards[rewardIndex].localized
        } else {
            rewardLabel.text = Dot.rewards[rewardIndex].localized
        }
        
        adView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.15) {
           self.adView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            self.adView.alpha = 1
            self.adImageView.alpha = 1
        }
        UIView.animate(withDuration: 0.05, delay: 0.2, options: .curveLinear, animations: {
            self.adView.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    func animateLose(with label: UILabel) {
        
        self.overlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.canTouchAndPrepare)))
        
        label.transform = CGAffineTransform(translationX: 0, y: 150)
        UIView.animate(withDuration: 0.2, animations: {
            label.alpha = 0.8
            label.transform = CGAffineTransform(translationX: 0, y: -10)
        }) { (_) in
            label.transform = CGAffineTransform.identity
            self.view.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func yesTapped(_ sender: UIButton) {
        overlayView.isUserInteractionEnabled = true
        idleTimeLeft = 15
        
        if isPremium {
            giveRewards()
            isEarned = false
            UIView.animate(withDuration: 0.2) {
                self.overlayView.alpha = 0
            }
            canTouchAndPrepare()
        } else {
            K.appDelegate.dotRewardedAd?.present(fromRootViewController: self, delegate: self)
            UIView.animate(withDuration: 0.2) {
                self.adView.alpha = 0
                self.adImageView.alpha = 0
            }
            
            log()
        }
    }
    
    func log() {
        Analytics.logEvent("lollipop_rewardedAd_entered", parameters: [
            "click_time": "\(Date())",
            "l": UserDefaults.standard.string(forKey: K.r) ?? "Unknown..."
        ])
    }
    
    
    func rewardedAd(_ rewardedAd: GADRewardedAd, userDidEarn reward: GADAdReward) {
        giveRewards()
    }
    
    func giveRewards() {
        isEarned = true
        hasSucceeded = false
        switch rewardIndex {
        case 0:
            isDoubleSpeed = true
        case 1:
            isHigherMush = true
        case 2:
            isHalfSize = true
            playerLabel.removeFromSuperview()
            playerLabel = UILabel(frame: .zero)
            setupplayerLabel()
            centerPlayerLabel()
        default:
            break
        }
    }
    
    func rewardedAdDidDismiss(_ rewardedAd: GADRewardedAd) {
        K.appDelegate.dotRewardedAd = K.appDelegate.createAndLoadReward(id: K.dotRewardedAdUnitID)
        idleTimeLeft = 15
        openIdleTimer()
        
        if isEarned {
            isEarned = false
            UIView.animate(withDuration: 0.2) {
                self.overlayView.alpha = 0
            }
            
            canTouchAndPrepare()
        } else {
            animateLose(with: failedLabel)
        }
    }
    
    func rewardedAd(_ rewardedAd: GADRewardedAd, didFailToPresentWithError error: Error) {
        animateLose(with: adsNotReadyLabel)
    }
    
    @IBAction func noTapped(_ sender: UIButton) {
        overlayView.isUserInteractionEnabled = true
        idleTimeLeft = 15
        UIView.animate(withDuration: 0.2, animations: {
            self.adView.alpha = 0
            self.adImageView.alpha = 0
        }) { (_) in
            self.canTouchAndPrepare()
        }
    }
    
    func setCorner() {
        easyLabel.layer.cornerRadius = easyLabel.bounds.width / 2
        succeedTopLabel.layer.cornerRadius = 5
        
        succeedLabel.layer.cornerRadius = 12
        succeedLabel.layer.borderWidth = 2
        succeedLabel.layer.borderColor = UIColor.white.cgColor
        failedLabel.layer.cornerRadius = 12
        failedLabel.layer.borderWidth = 2
        failedLabel.layer.borderColor = UIColor.white.cgColor
        adsNotReadyLabel.layer.cornerRadius = 12
        adsNotReadyLabel.layer.borderWidth = 2
        adsNotReadyLabel.layer.borderColor = UIColor.white.cgColor
        adView.layer.cornerRadius = 12
        adView.layer.borderWidth = 2
        adView.layer.borderColor = #colorLiteral(red: 0.3085834764, green: 0.376998802, blue: 1, alpha: 1).cgColor
        
        yesButton.layer.cornerRadius = 8
        noButton.layer.cornerRadius = 8
        
        exitButton.layer.cornerRadius = 8
        exitButton.alpha = isFromMission ? 1 : 0
        idleProgressBar.isHidden = isFromMission ? true : false
    }
    
    func waitAnimation() {
        easyLabel.alpha = 1
        self.animateOneCircle()
        var circle = 0
        var openIdle = true
        let maxCircle = Int.random(in: 1...2)
        easyTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true, block: { [weak self] (_) in
            
            guard let self = self else {return}
            
            if circle <= maxCircle {
                circle += 1
                self.animateOneCircle()
            } else {
                
                self.tipLabel.alpha = 0
                UIView.animate(withDuration: 0.5) {
                    self.easyLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
                    self.easyLabel.alpha = 0
                }
                UIView.animate(withDuration: 0.5, delay: 0.4, options: .curveLinear, animations: {
                    self.playerLabel.alpha = 1
                }) { (_) in
                    if !self.isFromMission && openIdle {
                        openIdle = false
                        self.openIdleTimer()
                    }
                    self.blinkTap()
                    self.canTouch = true
                }
            }
        })
        easyTimer?.tolerance = 0.1
    }
    
    func openIdleTimer() {
        idleTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (_) in
            self.idleTimeLeft -= 1
            self.realTimePassed += 1
            if self.realTimePassed == 20 {
                self.showExit()
            }
        })
        idleTimer?.tolerance = 0.1
    }
    
    func blinkTap() {
        self.tapToStartLabel.alpha = 1
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.4) {
            self.tapToStartLabel.alpha = 0
        }
    }
    
    func animateOneCircle() {
        UIView.animate(withDuration: 0.4, delay: 0, options: .curveLinear, animations: {
            self.easyLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        }, completion: nil)
        UIView.animate(withDuration: 0.4, delay: 0.4, options: .curveLinear, animations: {
            self.easyLabel.transform = CGAffineTransform(rotationAngle: 2 * CGFloat.pi)
        }, completion: nil)
    }
    
    fileprivate var turnedPink = true
    @IBAction func exitButtonTapped(_ sender: UIButton) {
        idleTimeLeft = 15
        if isFromMission {
            if turnedPink {
                ARMissionViewController.backFromGame = true
                UserDefaults.standard.set(UserDefaults.standard.integer(forKey: K.interstitialCount) + 1, forKey: K.interstitialCount)
                performSegue(withIdentifier: K.exitFromDotToMission, sender: self)
            } else {
                sender.backgroundColor = .systemPink
                turnedPink = true
            }
        } else {
            performSegue(withIdentifier: K.dotToPicSegue, sender: self)
        }
    }
  
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        idleTimeLeft = 15
        if !canTouch {return}
        
        bestTimeLabel.alpha = 0
        
        if self.easyTimer != nil {
            self.easyTimer?.invalidate()
            self.easyTimer = nil
        }
        
        if isFromMission {
            exitButton.backgroundColor = #colorLiteral(red: 1, green: 0.1764705882, blue: 0.3333333333, alpha: 0.1)
            turnedPink = false
        }
        
        if gameState == .ready {
            startGame()
        }
        
        if let touchLocation = event?.allTouches?.first?.location(in: view) {
            movePlayer(to: touchLocation)
            moveEnemies(to: touchLocation)
        }
    }
    
  // MARK: - Selectors
    @objc func generateEnemy(timer: Timer) {
        let screenEdge = ScreenEdge.init(rawValue: Int(arc4random_uniform(4)))
        let screenBounds = UIScreen.main.bounds
        var position: CGFloat = 0
        
        switch screenEdge! {
        case .left, .right:
            position = CGFloat(arc4random_uniform(UInt32(screenBounds.height)))
        case .top, .bottom:
            position = CGFloat(arc4random_uniform(UInt32(screenBounds.width)))
        }
    
        let enemyView = UIView(frame: .zero)
        enemyView.bounds.size = CGSize(width: radius, height: radius)
        enemyView.backgroundColor = getRandomColor()
        
        let polls = isHigherMush ? [1,2,3,4,5,6,7,8,9,10] : [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]
        if mushroom==nil && (polls.randomElement() ?? 1)==1 {
            generateMush()
        }
        
        if mushroomBk != nil && !stopAnimatingMush {
            animateMushBk()
        }
    
        switch screenEdge! {
        case .left:
          enemyView.center = CGPoint(x: 0, y: position)
        case .right:
          enemyView.center = CGPoint(x: screenBounds.width, y: position)
        case .top:
          enemyView.center = CGPoint(x: position, y: screenBounds.height)
        case .bottom:
          enemyView.center = CGPoint(x: position, y: 0)
        }
        
        view.addSubview(enemyView)

        let duration = getEnemyDuration(enemyView: enemyView)
        let enemyAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear, animations: { [weak self] in
            if let strongSelf = self {
              enemyView.center = strongSelf.playerLabel.center
            }
          }
        )
        enemyAnimator.startAnimation()
        enemyAnimators.append(enemyAnimator)
        enemyViews.append(enemyView)
    }
    
    func showExit() {
        if isFromMission {return}
        
        UIView.animate(withDuration: 0.3, animations: {
            self.exitButton.alpha = 1
            self.exitButton.backgroundColor = .systemPink
            self.turnedPink = true
        }) { (_) in
            UIView.animate(withDuration: 0.3) {
                self.idleProgressBar.transform = CGAffineTransform(translationX: 0, y: -(self.exitButton.bounds.height+20))
            }
        }
    }
    
    func generateMush() {
        mushroom = UIImageView(frame: .zero)
        mushroom?.image = UIImage(named: "mushroom")
        mushroom?.contentMode = .scaleAspectFill
        mushroom?.bounds.size = CGSize(width: radius*3, height: radius*3)
        mushroom?.backgroundColor = .clear
        mushroom?.center = CGPoint(x: CGFloat.random(in: 30.0...UIScreen.main.bounds.width-30), y: CGFloat.random(in: 150...UIScreen.main.bounds.height-200))
        mushroom?.alpha = 0
        view.addSubview(mushroom ?? overlayView)
        UIView.animate(withDuration: 1) {
            self.mushroom?.alpha = 1
        }
        
        let bkWidth = (mushroom?.layer.bounds.width ?? 0) * 1.8
        let bkHeight = (mushroom?.layer.bounds.height ?? 0) * 1.8
        mushroomBk = UIView(frame: CGRect(x: (mushroom?.layer.position.x ?? 0) - bkWidth/2, y: (mushroom?.layer.position.y ?? 0) - bkHeight/2, width: bkWidth, height: bkHeight))
        mushroomBk?.layer.cornerRadius = bkWidth / 2
        mushroomBk?.backgroundColor = UIColor.systemPink.withAlphaComponent(0.5)
        mushroomBk?.alpha = 0
        view.addSubview(mushroomBk ?? overlayView)
        mushroom?.layer.zPosition = 1
    }
    
    func animateMushBk() {
        UIView.animate(withDuration: 0.3, animations: {
            self.mushroomBk?.alpha = 1
        }) { (_) in
            UIView.animate(withDuration: 0.2) {
                if !self.stopAnimatingMush {
                    self.mushroomBk?.alpha = 0
                }
            }
        }
    }
  
    @objc func tick(sender: CADisplayLink) {
        updateCountUpTimer(timestamp: sender.timestamp)
        checkCollision()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}

fileprivate extension LollipopViewController {
    func setupplayerLabel() {
        if !isHalfSize {
            playerLabel.bounds.size = CGSize(width: radius * 4, height: radius * 3.5)
            playerLabel.font = UIFont.systemFont(ofSize: 35)
            playerLabel.layer.cornerRadius = playerLabel.bounds.height/1.8
        } else {
            playerLabel.bounds.size = CGSize(width: radius * 2.3, height: radius * 2)
            playerLabel.layer.cornerRadius = playerLabel.bounds.width/2
            playerLabel.layer.zPosition = 2
        }
        
        playerLabel.layer.masksToBounds = true
        playerLabel.backgroundColor = .clear
        playerLabel.text = AlarmViewController.dot
        view.addSubview(playerLabel)
    }
  
    func startEnemyTimer() {
        enemyTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(generateEnemy(timer:)), userInfo: nil, repeats: true)
    }
  
    func stopEnemyTimer() {
        guard let enemyTimer = enemyTimer,
            enemyTimer.isValid else {
            return
        }
        enemyTimer.invalidate()
    }
  
    func startDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick(sender:)))
        displayLink?.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
    }
      
    func stopDisplayLink() {
        displayLink?.isPaused = true
        displayLink?.remove(from: RunLoop.main, forMode: RunLoop.Mode.default)
        displayLink = nil
    }
  
    func getRandomColor() -> UIColor {
        let index = arc4random_uniform(UInt32(colors.count))
        return colors[Int(index)]
    }
  
    func getEnemyDuration(enemyView: UIView) -> TimeInterval {
        let dx = playerLabel.center.x - enemyView.center.x
        let dy = playerLabel.center.y - enemyView.center.y
        return TimeInterval(sqrt(dx * dx + dy * dy) / enemySpeed)
    }
    
    func gameOver() {
        stopGame()
        showOverlay()
    }
  
    func stopGame() {
        stopEnemyTimer()
        stopDisplayLink()
        stopAnimators()
        gameState = .gameOver
    }
  
    func prepareGame() {
        succeedLabel.text = "Good Job 😁".localized
        isViewDisappearing = false
        bestTimeLabel.alpha = 1
        bestTimeLabel.text = "\("Best Time".localized): \(Int(UserDefaults.standard.double(forKey: K.dotBestTime))==0 ? String(0) : String(format: "%.1f", UserDefaults.standard.double(forKey: K.dotBestTime)))\("s".localized)"
        progressBar.setProgress(0.01, animated: true)
        overlayView.alpha = 0
        succeedTopLabel.alpha = 0
        hasSucceeded = false
    
        removeEnemies()
        removeMush()
        centerPlayerLabel()
        popPlayerLabel()
        tapToStartLabel.isHidden = false
        clockLabel.text = "00:00.000"
        gameState = .ready
    }
  
    func startGame() {
        startEnemyTimer()
        startDisplayLink()
        tapToStartLabel.isHidden = true
        beginTimestamp = 0
        gameState = .playing
        
        timesPlayed += 1
        Analytics.logEvent("lollipop_played", parameters: [
            "times_played": timesPlayed,
            "l": UserDefaults.standard.string(forKey: K.r) ?? "Unknown..."
        ])
    }
  
    func removeEnemies() {
        enemyViews.forEach {
          $0.removeFromSuperview()
        }
        enemyViews = []
    }
    
    func removeMush() {
        mushroom?.removeFromSuperview()
        mushroomBk?.removeFromSuperview()
        mushroom = nil
        mushroomBk = nil
    }
  
    func stopAnimators() {
        playerAnimator?.stopAnimation(true)
        playerAnimator = nil
        enemyAnimators.forEach {
          $0.stopAnimation(true)
        }
        enemyAnimators = []
    }
  
    func updateCountUpTimer(timestamp: TimeInterval) {
        if beginTimestamp == 0 {
            beginTimestamp = timestamp
        }
        elapsedTime = timestamp - beginTimestamp
        
        if Float(elapsedTime) <= Float(goal) {
            
            progressBar.setProgress(Float(elapsedTime)/Float(goal), animated: true)
            
        } else if !hasSucceeded {
            
            if Int(elapsedTime) == Dot.levels[5].goal {
                UserDefaults.standard.set(true, forKey: K.dotUnlocked)
            }
            
            showExit()
            
            hasSucceeded = true
            succeedTopLabel.transform = CGAffineTransform(translationX: 0, y: 150)
            UIView.animate(withDuration: 0.3, animations: {
                self.succeedTopLabel.alpha = 1
                self.succeedTopLabel.transform = CGAffineTransform(translationX: 0, y: -10)
            }) { (_) in
                self.succeedTopLabel.transform = CGAffineTransform.identity
            }
        }
        clockLabel.text = format(timeInterval: elapsedTime)
    }
  
    func format(timeInterval: TimeInterval) -> String {
        let interval = Int(timeInterval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let milliseconds = Int(timeInterval * 1000) % 1000
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }
  
    func checkCollision() {
        
        if isViewDisappearing {return}
        
        enemyViews.forEach {
            if let playerFrame = playerLabel.layer.presentation()?.frame,
                let enemyFrame = $0.layer.presentation()?.frame,
                playerFrame.intersects(enemyFrame) {
                
                AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(4095), nil)
                
                if isHalfSize {
                    isHalfSize = false
                    playerLabel.removeFromSuperview()
                    playerLabel = UILabel(frame: .zero)
                    setupplayerLabel()
                }
                
                isDoubleSpeed = false
                isHigherMush = false
                rewardIndex = -1
                
                if elapsedTime > UserDefaults.standard.double(forKey: K.dotBestTime) {
                    UserDefaults.standard.set(elapsedTime, forKey: K.dotBestTime)
                    self.succeedLabel.text = "\("A New Record".localized) \(["🥰","😜","🥳","✊"].randomElement() ?? "🥳")     "
                }
    
                self.gameOver()
            }
        }
        if let playerFrame = playerLabel.layer.presentation()?.frame {
            if let mushroomFrame = mushroom?.layer.presentation()?.frame,
                playerFrame.intersects(mushroomFrame) {
                
                if stopAnimatingMush {return}
                
                stopAnimatingMush = true
                
                self.mushroomBk?.alpha = 1
                self.mushroomBk?.backgroundColor = .clear
                self.mushroomBk?.layer.masksToBounds = true
                self.mushroomBk?.layer.borderWidth = 5
                self.mushroomBk?.layer.borderColor = UIColor.systemPink.cgColor
                
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
                UIView.animate(withDuration: 1) {
                    self.mushroomBk?.transform = CGAffineTransform(scaleX: 100, y: 100)
                }
                
                for i in 0..<(self.enemyViews.count<5 ? self.enemyViews.count : 5 ) {
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5 + Double(i)*0.15) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
                    self.removeEnemies()
                }
                
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
                    self.stopAnimatingMush = false
                    self.removeMush()
                }
            }
        }
    }
  
    func movePlayer(to touchLocation: CGPoint) {
        playerAnimator = UIViewPropertyAnimator(duration: isDoubleSpeed ? playerAnimationDuration/1.8 : playerAnimationDuration,
                                                dampingRatio: 0.5,
                                                animations: { [weak self] in
                                                  self?.playerLabel.center = touchLocation
                                                })
        playerAnimator?.startAnimation()
    }
  
    func moveEnemies(to touchLocation: CGPoint) {
        for (index, enemyView) in enemyViews.enumerated() {
            let duration = getEnemyDuration(enemyView: enemyView)
            enemyAnimators[index] = UIViewPropertyAnimator(duration: duration,
                                                         curve: .linear,
                                                         animations: {
                                                           enemyView.center = touchLocation
                                                        })
            enemyAnimators[index].startAnimation()
        }
    }
  
    func centerPlayerLabel() {
        playerLabel.center = view.center
    }
  
    func popPlayerLabel() {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [0, 0.2, -0.2, 0.2, 0]
        animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.duration = CFTimeInterval(0.7)
        animation.isAdditive = true
        animation.repeatCount = 1
        animation.beginTime = CACurrentMediaTime()
        playerLabel.layer.add(animation, forKey: "pop")
    }
  
}
