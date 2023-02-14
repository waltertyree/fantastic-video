//
//  ViewController.swift
//  ritrok
//
//  Created by Walter Tyree on 12/28/22.
//

import UIKit
import AVKit
import VideoEditorSDK
import CoreLocation


class ViewController: UIViewController {

  //UI Elements
  @IBOutlet var emptyDirectoryLabel: UILabel!
  @IBOutlet var createNewButton: UIButton!

  //AV Elements
  var videos: [URL] = []
  var player = AVQueuePlayer()
  var playerLooper: AVPlayerLooper?
  var currentVideo: URL?

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    loadVideos()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    setupVideoPlayer()


  }

  func loadVideos() {
    //get a handle to the documents directory for this app
    guard let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { logger.error("Documents directory not found"); return}

    //documentDirectory.append(component: "finished")

    if let files = try? FileManager.default.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil) {
      videos = files
    }

  }

  func setupVideoPlayer() {
    guard let currentVideo = videos.first else {logger.error("No videos to play"); return}
    emptyDirectoryLabel.isHidden = true
    self.currentVideo = currentVideo

    let video = AVPlayerItem(url: currentVideo)
    let playerLayer = AVPlayerLayer(player: player)
    playerLayer.frame = self.view.layer.bounds
    playerLayer.videoGravity = .resizeAspect

    self.view.layer.addSublayer(playerLayer)

    // Create a new player looper with the queue player and template item
    playerLooper = AVPlayerLooper(player: player, templateItem: video)

    self.player.play()
    
  }

  @IBAction func nextVideo(_ sender: Any) {
    logger.info("Swiped Up")
    guard let currentVideo = self.currentVideo else { logger.error("No current video"); return }
    let currentIndex = videos.firstIndex(of: currentVideo)
    var nextVideo = videos.index(after: currentIndex!)
    if nextVideo == videos.count {
      nextVideo = 0
    }

    self.currentVideo = videos[nextVideo]
    let newVideo = AVPlayerItem(url: self.currentVideo!)


    //Disable looping so the looper can clean up before we switch to the next video
    playerLooper?.disableLooping()

    // Create a new player looper with the queue player and template item
    playerLooper = AVPlayerLooper(player: player, templateItem: newVideo)

    player.play()
   // self.player?.rate = 1.0
  }

  @IBAction func togglePlayback(_ sender: Any) {

    if player.rate > 0.0 {
      player.rate = 0.0
    } else {
      player.rate = 1.0
    }
  }

  fileprivate func styleCameraButton(_ button: Button) {
    button.layer.cornerRadius = 20.0
    button.layer.borderWidth = 2.0
    button.layer.backgroundColor = UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 0.3).cgColor
    button.layer.borderColor = UIColor.orange.cgColor
  }

  @IBAction func recordVideo(_ sender: Any) {
    logger.info("Tapped record")
    let config = Configuration { builder in
      builder.configureCameraViewController { options in


        //options.includeUserLocation = false


        // configure camera
        options.allowedCameraPositions = [.back, .front]
        options.allowedRecordingModes = [.video]
        options.allowedRecordingOrientations = [.portrait]

        options.backgroundColor = UIColor.brown
        options.filterSelectorButtonConfigurationClosure = { button in
          self.styleCameraButton(button)
          button.actionClosure = { _ in 
            logger.info("filter tapped")
          }
        }

        options.switchCameraButtonConfigurationClosure = { button in
          self.styleCameraButton(button)
        }

        options.cancelButtonConfigurationClosure = { button in
          self.styleCameraButton(button)
        }

        options.flashButtonConfigurationClosure = { button in
          self.styleCameraButton(button)
          // "remove" the flash button
          //          button.isUserInteractionEnabled = false
          //          button.layer.opacity = 0.0
        }

        options.filterSelectorButtonConfigurationClosure = { button in
          self.styleCameraButton(button)
        }

        // allow cancel
        options.showCancelButton = true

        // remove the camera roll
        options.showCameraRoll = false
      }
    }


    let cameraViewController = CameraViewController(configuration: config)
    cameraViewController.locationAccessRequestClosure = { locationManager in
      if locationManager.authorizationStatus == .notDetermined {
        locationManager.requestWhenInUseAuthorization()
      }
    }

    cameraViewController.cancelBlock = { [weak self] in
      self?.dismiss(animated: true)
    }

    // The `completionBlock` will be called when the user selects a video from the camera roll
    // or finishes recording a video.
    cameraViewController.completionBlock = { [weak self] result in
      // Create a `Video` from the `URL` object.
      guard let url = result.url else { return }
      let video = Video(url: url)

      // Dismiss the camera view controller and open the video editor after dismissal.
      self?.dismiss(animated: false, completion: {
        let config = Configuration { builder in
          builder.configureBrushToolController { options in
            options.allowedBrushTools = [.color, .hardness]
          }

          builder.configureVideoEditViewController { options in
            options.backgroundColor = UIColor.brown
            options.menuBackgroundColor = UIColor.orange
            options.overlayButtonConfigurationClosure = { button, action in
              self?.styleCameraButton(button)
            }
            options.discardButtonConfigurationClosure = { button in
              self?.styleCameraButton(button)

            }
            options.applyButtonConfigurationClosure = { button in
              self?.styleCameraButton(button)
            }

            options.titleViewConfigurationClosure = { view in
              view.backgroundColor = UIColor.brown
            }

            options.menuItems = [PhotoEditMenuItem.tool(.createTrimToolItem()!), PhotoEditMenuItem.tool(.createAudioToolItem()!),
              PhotoEditMenuItem.tool(.createBrushToolItem()!)]
          }
        }
        // Create and present the video editor. Make this class the delegate of it to handle export and cancelation.
        // Passing the `result.model` to the editor to preserve selected filters.
        let videoEditViewController = VideoEditViewController(videoAsset: video, configuration: config, photoEditModel: result.model)
        videoEditViewController.delegate = self
        videoEditViewController.modalPresentationStyle = .fullScreen
        self?.present(videoEditViewController, animated: false, completion: nil)
      })
    }
    cameraViewController.modalPresentationStyle = .fullScreen
    self.present(cameraViewController, animated: true)
  }
}

extension ViewController: VideoEditViewControllerDelegate {
  func videoEditViewControllerDidFinish(_ videoEditViewController: ImglyKit.VideoEditViewController, result: ImglyKit.VideoEditorResult) {
    logger.info("new video: \(result.output.url)")
    do {
      guard let documentDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else { logger.error("Documents directory not found"); return}
      let filePath = documentDirectory.appending(component: result.output.url.lastPathComponent)
      try FileManager.default.moveItem(atPath: result.output.url.path(), toPath: filePath.path())
    } catch (let error as NSError) {
      logger.error("could not copy finished file: \(error.localizedDescription)")
    }
      self.dismiss(animated: true, completion: nil)

  }

  func videoEditViewControllerDidFail(_ videoEditViewController: ImglyKit.VideoEditViewController, error: ImglyKit.VideoEditorError) {
    logger.error("\(error.localizedDescription)")
       // Dismissing the editor.
       self.dismiss(animated: true, completion: nil)

  }

  func videoEditViewControllerDidCancel(_ videoEditViewController: ImglyKit.VideoEditViewController) {
    self.dismiss(animated: true, completion: nil)

  }


}

