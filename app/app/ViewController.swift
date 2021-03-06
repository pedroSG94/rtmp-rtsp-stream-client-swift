//
//  ViewController.swift
//  app
//
//  Created by Pedro on 04/09/2020.
//  Copyright © 2020 pedroSG94. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, GetMicrophoneData, GetCameraData, GetAacData, GetH264Data,  ConnectCheckerRtsp {
    
    
    @IBOutlet weak var tvEndpoint: UITextField!
    @IBOutlet weak var bStartStream: UIButton!
    @IBOutlet weak var cameraview: UIView!
    
    private var client: RtspClient?
    private var microphone: MicrophoneManager?
    private var cameraManager: CameraManager?
    private var audioEncoder: AudioEncoder?
    private var videoEncoder: VideoEncoder?
    private var endpoint: String? = nil
    
    @IBAction func onClickstartStream(_ sender: UIButton) {
        endpoint = tvEndpoint.text!
        client = RtspClient(connectCheckerRtsp: self)
        cameraManager = CameraManager(cameraView: cameraview, callback: self)
        microphone = MicrophoneManager(callback: self)
        videoEncoder = VideoEncoder(callback: self)
        audioEncoder = AudioEncoder(inputFormat: microphone!.getInputFormat(), callback: self)
        
        client?.setAudioInfo(sampleRate: 44100, isStereo: true)
        audioEncoder?.prepareAudio(sampleRate: 44100, channels: 2, bitrate: 64 * 1000)
        videoEncoder?.prepareVideo()
        microphone?.start()
        cameraManager?.createSession()
    }
    
    func onConnectionSuccessRtsp() {
        //showMessage(message: "connection success")
    }
    
    func onConnectionFailedRtsp(reason: String) {
        showMessage(message: "connection failed: \(reason)")
        stopStream()
    }
    
    func onNewBitrateRtsp(bitrate: UInt64) {
        print("new bitrate: \(bitrate)")
    }
    
    func onDisconnectRtsp() {
        showMessage(message: "disconnected")
    }
    
    func onAuthErrorRtsp() {
        showMessage(message: "auth error")
    }
    
    func onAuthSuccessRtsp() {
        showMessage(message: "auth success")
    }
    
    func getAacData(frame: Frame) {
        client?.sendAudio(frame: frame)
    }
    
    func getPcmData(from buffer: AVAudioPCMBuffer) {
        //audioEncoder?.encodeFrame(from: buffer)
    }
    
    func getH264Data(frame: Frame) {
        client?.sendVideo(frame: frame)
    }
    
    func getSpsAndPps(sps: Array<UInt8>, pps: Array<UInt8>) {
        print("connecting... \(sps) - \(pps)")
        client?.setVideoInfo(sps: sps, pps: pps, vps: nil)
        client?.connect(url: "rtsp://192.168.1.133:8554/live/pedro")
    }
    
    func getYUVData(from buffer: CMSampleBuffer) {
        videoEncoder?.encodeFrame(buffer: buffer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validatePermissions()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (context) -> Void in
            self.cameraManager?.viewTransation()
        }, completion: { (context) -> Void in

        })
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopStream()
    }
    
    private func stopStream() {
        microphone?.stop()
        cameraManager?.stop()
        audioEncoder?.stop()
        videoEncoder?.stop()
        client?.disconnect()
    }
    
    func validatePermissions() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            break
        case .denied:
            break
        case .undetermined:
            break
        default:
            break
        }
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
                if response {
                    //access granted
                } else {

                }
            }
    }
    
    func request() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
               
            } else {
                
            }
        }
    }
    
    private func showMessage(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler:nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

