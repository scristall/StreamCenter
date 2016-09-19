import AVKit
import UIKit
import Foundation

enum StreamSourceQuality: String {
    case Source
    case High
    case Medium
    case Low
}

class TwitchVideoViewController : UIViewController {
    internal var videoView : VideoView?
    fileprivate var videoPlayer : AVPlayer?
    fileprivate var chatView : TwitchChatView?

    internal var modalMenu : ModalMenuView?
    fileprivate var modalMenuOptions : [String : [MenuOption]]?

    internal var leftSwipe : UISwipeGestureRecognizer!
    internal var rightSwipe : UISwipeGestureRecognizer!
    internal var shortTap : UITapGestureRecognizer!
    internal var longTap : UILongPressGestureRecognizer!

    fileprivate var streams : [TwitchStreamVideo]?
    fileprivate var currentStream : TwitchStream?
    fileprivate var currentStreamVideo : TwitchStreamVideo?

    internal var twitchApiClient : TwitchApi!
    internal var mainQueueRunner : AsyncMainQueueRunner!
    
    convenience init(stream : TwitchStream, twitchClient : TwitchApi, mainQueueRunner : AsyncMainQueueRunner) {
        self.init(nibName: nil, bundle: nil)
        self.currentStream = stream
        self.twitchApiClient = twitchClient
        self.mainQueueRunner = mainQueueRunner
        
        self.view.backgroundColor = UIColor.black
        
        //Gestures configuration
        longTap = UILongPressGestureRecognizer(target: self, action: #selector(TwitchVideoViewController.handleLongPress(_:)))
        longTap.cancelsTouchesInView = true
        self.view.addGestureRecognizer(longTap)
        
        shortTap = UITapGestureRecognizer(target: self, action: #selector(TwitchVideoViewController.pause))
        shortTap.allowedPressTypes = [NSNumber(value: UIPressType.playPause.rawValue as Int)]
        self.view.addGestureRecognizer(shortTap)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TwitchVideoViewController.handleMenuPress))
        gestureRecognizer.allowedPressTypes = [NSNumber(value: UIPressType.menu.rawValue)]
        gestureRecognizer.cancelsTouchesInView = true
        self.view.addGestureRecognizer(gestureRecognizer)
        
        leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(TwitchVideoViewController.swipe(_:)))
        leftSwipe.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(leftSwipe)
        
        rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(TwitchVideoViewController.swipe(_:)))
        rightSwipe.direction = UISwipeGestureRecognizerDirection.right
        rightSwipe.isEnabled = false
        self.view.addGestureRecognizer(rightSwipe)
            
        //Modal menu options
        self.modalMenuOptions = [
            "Stream Quality" : [
                MenuOption(title: StreamSourceQuality.Source.rawValue, enabled: false, onClick: self.handleQualityChange),
                MenuOption(title: StreamSourceQuality.High.rawValue, enabled: false, onClick: self.handleQualityChange),
                MenuOption(title: StreamSourceQuality.Medium.rawValue, enabled: false, onClick: self.handleQualityChange),
                MenuOption(title: StreamSourceQuality.Low.rawValue, enabled: false, onClick: self.handleQualityChange)
            ]
        ]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.twitchApiClient.getStreamsForChannel(self.currentStream!.channel.name) {
            (streams, error) in
            
            if let streams = streams , streams.count > 0 {
                self.streams = streams
                self.currentStreamVideo = streams[0]
                let streamAsset = AVURLAsset(url: self.currentStreamVideo!.url)
                let streamItem = AVPlayerItem(asset: streamAsset)
                
                self.videoPlayer = AVPlayer(playerItem: streamItem)
                
                self.mainQueueRunner.runOnMainQueue({ () -> () in
                    self.initializePlayerView()
                })
            } else {
                let alert = UIAlertController(title: "Uh-Oh!", message: "There seems to be an issue with the stream. We're very sorry about that.", preferredStyle: .alert)
                
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action) -> Void in
                    self.dismiss(animated: true, completion: nil)
                }))
                
                self.mainQueueRunner.runOnMainQueue({ () -> () in
                    self.present(alert, animated: true, completion: nil)
                })
            }
        }
    }
    
    /*
    * viewWillDisappear(animated: Bool)
    *
    * Overrides the default method to shut off the chat connection if present
    * and the free video assets
    */
    override func viewWillDisappear(_ animated: Bool) {
        
        self.chatView?.stopDisplayingMessages()
        self.chatView?.removeFromSuperview()
        self.chatView = nil
        
        self.videoView?.removeFromSuperview()
        self.videoView?.setPlayer(nil)
        self.videoView = nil
        self.videoPlayer = nil

        super.viewWillDisappear(animated)
    }
    
    /*
    * initializePlayerView()
    *
    * Initializes a player view with the current video player
    * and displays it
    */
    func initializePlayerView() {
        self.videoView = VideoView(frame: videoViewFrame())
        self.videoView?.setPlayer(self.videoPlayer!)
        self.videoView?.setVideoFillMode(AVLayerVideoGravityResizeAspect)
        
        self.view.addSubview(self.videoView!)
        self.videoPlayer?.play()
    }
    
    /*
    * initializeChatView()
    *
    * Initializes a chat view for the current channel
    * and displays it
    */
    func initializeChatView() {
        self.chatView = TwitchChatView(frame: CGRect(x: 0, y: 0, width: 400, height: self.view!.bounds.height), channel: self.currentStream!.channel)
        self.chatView!.startDisplayingMessages()
        self.chatView?.backgroundColor = UIColor.white
        self.view.addSubview(self.chatView!)
    }
    
    /*
    * handleLongPress()
    *
    * Handler for the UILongPressGestureRecognizer of the controller
    * Presents the modal menu if it is initialized
    */
    func handleLongPress(_ longPressRecognizer: UILongPressGestureRecognizer) {
        if longPressRecognizer.state == UIGestureRecognizerState.began {
            if self.modalMenu == nil {
                modalMenu = ModalMenuView(frame: self.view.bounds,
                    options: self.modalMenuOptions!,
                    size: CGSize(width: self.view.bounds.width/3, height: self.view.bounds.height/1.5))
                
                modalMenu!.center = self.view.center
            }
            
            guard let modalMenu = self.modalMenu else {
                return
            }
            
            if modalMenu.isDescendant(of: self.view) {
                dismissMenu()
            } else {
                modalMenu.alpha = 0
                self.view.addSubview(self.modalMenu!)
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    self.modalMenu?.alpha = 1
                    self.view.setNeedsFocusUpdate()
                })
            }
        }
    }
    
    /*
    * handleMenuPress()
    *
    * Handler for the UITapGestureRecognizer of the modal menu
    * Dismisses the modal menu if it is present
    */
    func handleMenuPress() {
        if dismissMenu() {
            return
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func dismissMenu() -> Bool {
        if let modalMenu = modalMenu {
            if self.view.subviews.contains(modalMenu) {
                //bkirchner: for some reason when i try to animate the menu fading away, it just goes to the homescreen - really odd
                UIView.animate(withDuration: 0.5, animations: { () -> Void in
                    modalMenu.alpha = 0
                }, completion: { (finished) -> Void in
                    Logger.Debug("Fade away animation finished: \(finished)")
                    if finished {
                        modalMenu.removeFromSuperview()
                    }
                })
//                modalMenu.removeFromSuperview()
                return true
            }
        }
        return false
    }
    
    /*
    * handleChatOnOff(sender : MenuItemView?)
    *
    * Handler for the chat option from the modal menu
    * Displays or remove the chat view
    */
    func handleChatOnOff(_ sender : MenuItemView?) {
        //NOTE(Olivier) : 400 width reduction at 16:9 is 225 height reduction
        self.mainQueueRunner.runOnMainQueue({ () -> () in
            if let menuItem = sender {
                if menuItem.isOptionEnabled() {     //                      Turn chat off
                    
                    self.hideChat()
                    
                    //Set the menu option accordingly
                    menuItem.setOptionEnabled(false)
                }
                else {                              //                      Turn chat on
                    
                    self.showChat()
                    
                    //Set the menu option accordingly
                    menuItem.setOptionEnabled(true)
                }
            }
        })
    }
    
    func showChat() {
        //Resize video view
        var frame = self.videoView?.frame
        frame?.size.width -= 400
        frame?.size.height -= 225
        frame?.origin.y += (225/2)
        
        
        
        //The chat view
        self.chatView = TwitchChatView(frame: CGRect(x: self.view.bounds.width, y: 0, width: 400, height: self.view!.bounds.height), channel: self.currentStream!.channel)
        self.chatView!.startDisplayingMessages()
        if let modalMenu = modalMenu {
            
            self.view.insertSubview(self.chatView!, belowSubview: modalMenu)
        } else {
            self.view.addSubview(self.chatView!)
        }
        
        rightSwipe.isEnabled = true
        leftSwipe.isEnabled = false
        
        //animate the showing of the chat view
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.chatView!.frame = CGRect(x: self.view.bounds.width - 400, y: 0, width: 400, height: self.view!.bounds.height)
            if let videoView = self.videoView, let frame = frame {
                videoView.frame = frame
            }
        }) 
    }
    
    func hideChat() {
        rightSwipe.isEnabled = false
        leftSwipe.isEnabled = true
        
        //animate the hiding of the chat view
        UIView.animate(withDuration: 0.5, animations: { () -> Void in
            self.videoView!.frame = self.videoViewFrame()
            self.chatView!.frame.origin.x = self.view.frame.maxX
        }, completion: { (finished) -> Void in
            self.chatView!.stopDisplayingMessages()
            self.chatView!.removeFromSuperview()
            self.chatView = nil
        }) 
    }
    
    func handleQualityChange(_ sender : MenuItemView?) {
        if let text = sender?.title?.text, let quality = StreamSourceQuality(rawValue: text) {
            var qualityIdentifier = "chunked"
            switch quality {
            case .Source:
                qualityIdentifier = "chunked"
            case .High:
                qualityIdentifier = "high"
            case .Medium:
                qualityIdentifier = "medium"
            case .Low:
                qualityIdentifier = "low"
            }
            if let streams = self.streams {
                for stream in streams {
                    if stream.quality == qualityIdentifier {
                        currentStreamVideo = stream
                        let streamAsset = AVURLAsset(url: stream.url as URL)
                        let streamItem = AVPlayerItem(asset: streamAsset)
                        self.videoPlayer?.replaceCurrentItem(with: streamItem)
                        dismissMenu()
                        return
                    }
                }
            }
        }
    }
    
    func pause() {
        if let player = self.videoPlayer {
            if player.rate == 1 {
                videoView?.alpha = 0.40
                player.pause()
            } else {
                if let currentVideo = currentStreamVideo {
                    //do this to bring it back in sync
                    let streamAsset = AVURLAsset(url: currentVideo.url as URL)
                    let streamItem = AVPlayerItem(asset: streamAsset)
                    player.replaceCurrentItem(with: streamItem)
                }
                videoView?.alpha = 1.0
                player.play()
            }
        }
    }
    
    func swipe(_ recognizer: UISwipeGestureRecognizer) {
        if recognizer.state == .ended {
            if recognizer.direction == .left {
                showChat()
            } else {
                hideChat()
            }
        }
    }

    func videoViewFrame() -> CGRect {
        let padding : CGFloat = 32
        let bounds : CGRect = self.view.bounds;

        return  CGRect(x: bounds.origin.x + padding,
                       y: bounds.origin.y + padding,
                       width: bounds.size.width - 2 * padding,
                       height: bounds.size.height - 2 * padding
        )
    }
}
