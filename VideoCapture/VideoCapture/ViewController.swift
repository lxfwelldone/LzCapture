//
//  ViewController.swift
//  VideoCapture
//
//  Created by mc on 2019/4/2.
//  Copyright © 2019年 lxf. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
     lazy var videoQueue = DispatchQueue.global()
     lazy var audioQueue = DispatchQueue.global()
     lazy var session = AVCaptureSession()
    
     var videoInput : AVCaptureDeviceInput? = nil
     var videoOutput : AVCaptureVideoDataOutput? = nil
    
     var audioInput : AVCaptureDeviceInput? = nil
     var audioOutput : AVCaptureAudioDataOutput? = nil

     var previewLayer : AVCaptureVideoPreviewLayer?
    
     var movieOutput : AVCaptureMovieFileOutput? = nil
}

extension ViewController {
    
    /**
     * 开始采集
    */
    @IBAction func startCaptrue() {
        
        if session.isRunning {
            return
        }
//       1 设置视频
        setupVideo()
        
//      2  设置音频
        setupAudio()
        
//      写入文件的output
        movieOutput = AVCaptureMovieFileOutput()
//        设置写入的稳定性
        let connection = movieOutput?.connection(with: AVMediaType.video)
        connection?.preferredVideoStabilizationMode = .auto
        session.addOutput(movieOutput!)

        
//      3一个预览图层
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer!.frame = view.bounds
        view.layer.insertSublayer(previewLayer!, at: 0)
        
//      4  开始采集
        session.startRunning()
        
//      将录制的视频写入到沙盒中
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日 HH时mm分ss秒"
        let fileName = formatter.string(from: today)
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first! + "/" + fileName + ".mp4"
        let url = URL(fileURLWithPath: path)
        movieOutput?.startRecording(to: url, recordingDelegate: self)
    }
    
//    结束采集
    @IBAction func stopCapture() {
        if session.isRunning == false {
            return
        }
        movieOutput?.stopRecording()
//        session.removeOutput(movieOutput!)
//
        session.stopRunning()
        previewLayer?.removeFromSuperlayer()
        session.removeInput(audioInput!)
        session.removeOutput(audioOutput!)
        session.removeInput(videoInput!)
        session.removeOutput(videoOutput!)

    }
    
    /**
    * 切换前后摄像头
    */
    @IBAction func exchangeCamera() {
        //1、获取正在使用的镜头
        guard var position = videoInput?.device.position else { return  }
        //2、获取未使用的镜头
        position = position == .front ? .back : .front
        //3、创建新的device
        let device = getCameraDevice(where: position)
        
        //4、创建新的input
        let input = try? AVCaptureDeviceInput(device: device)
        
        //5、改变session中的input
        session.beginConfiguration()
        session.removeInput(videoInput!)
        session.addInput(input!)
        session.commitConfiguration()
        videoInput = input
    }
}

extension ViewController {
// 音频
    fileprivate func setupAudio(){
        // 1 获取麦克风
        guard let device = AVCaptureDevice.default(for: AVMediaType.audio) else { return }
        
        // 2 设置音频的 input
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        audioInput = input
        session.addInput(audioInput!)

        // 3 设置音频的 output
        audioOutput = AVCaptureAudioDataOutput()
        audioOutput!.setSampleBufferDelegate(self, queue: audioQueue)
        session.addOutput(audioOutput!)
    }
    
// 视频
    fileprivate func setupVideo(){
        
        //1 获取摄像头-前置或摄像头
        let device = getCameraDevice(where: AVCaptureDevice.Position.front)
        
        //2 设置video的input
        guard let input = try? AVCaptureDeviceInput(device: device) else { return }
        videoInput = input
        session.addInput(videoInput!)
        
        //3 设置video的output
        videoOutput = AVCaptureVideoDataOutput()
        videoOutput!.setSampleBufferDelegate(self, queue: videoQueue)
        session.addOutput(videoOutput!)
    }
    
    /*
     * 前置摄像头还是后置摄像头 frontOrBack:position
    */
    open func getCameraDevice(where frontOrBack : AVCaptureDevice.Position) -> AVCaptureDevice {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        assert(devices.count > 0, "当前设备摄像头不可用")
        let device = devices.filter({ $0.position == frontOrBack}).first
        return device!
    }
}


//遵守协议 - AVCaptureVideoDataOutputSampleBufferDelegate 和 AVCaptureAudioDataOutputSampleBufferDelegate
extension ViewController : AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        if output == audioOutput {
          print("采集音频")
        }
        if output == videoOutput {
            print("采集视频----------------")
        }
    }
}

//遵守协议 AVCaptureFileOutputRecordingDelegate
extension ViewController : AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("开始写入文件")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("结束写入文件")
    }
}
