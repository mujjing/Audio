//
//  ViewController.swift
//  Audio
//
//  Created by Jh's MacbookPro on 2020/01/01.
//  Copyright © 2020 JH. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVAudioPlayerDelegate, AVAudioRecorderDelegate {

    var audioPlayer : AVAudioPlayer! //AVAudioPlayer의 인스턴스 변수
    var audioFile : URL! // 재생할 오디오와 파일명 변수
    let MAX_VOLUME : Float = 10.0 // 최대볼륨, 실수형 상수
    var ProgressTimer : Timer! // 타이머를 위한 변수
    
    let timePlayerSelector:Selector = #selector(ViewController.updatePlayTime)
    let timeRecordSelector:Selector = #selector(ViewController.updateRecordTime)
    
    @IBOutlet var pvProgressPlay: UIProgressView!
    
    @IBOutlet var currentTime: UILabel!
    
    @IBOutlet var endTime: UILabel!
    
    @IBOutlet var btnPlay: UIButton!
    
    @IBOutlet var btnPause: UIButton!
    
    @IBOutlet var btnStop: UIButton!
    
    @IBOutlet var slVolume: UISlider!
    
    @IBOutlet var onRecord: UIButton!
    
    @IBOutlet var recordTime: UILabel!
    
    var audioRecorder : AVAudioRecorder! //audioRecorder 인스턴스를 추가
    var isRecordMode  = false // 현재 녹음모드 하는 것을 나타낼 isRecordMode를 추가 기본값은 false로 하여 처음 앱을 실행 할 때는 음악재생모드로 실행하게 함
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        selectAudioFile()
        
        if !isRecordMode{
        initPlay()
            onRecord.isEnabled = false
            recordTime.isEnabled = false
        }else{
            initRecord()
        }
        
    }
    
    func selectAudioFile(){
        if !isRecordMode {
            audioFile = Bundle.main.url(forResource: "어벤져스", withExtension: "mp3")
        } else {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFile = documentDirectory.appendingPathComponent("recordFile.m4a")
        }// 녹음모드 일 때는 새 파일인 recordFile.m4a가 생성된다
    }
    
    func initRecord(){
        let recordSettings = [
            AVFormatIDKey : NSNumber(value: kAudioFormatAppleLossless as UInt32),
            AVEncoderAudioQualityKey : AVAudioQuality.max.rawValue,
            AVEncoderBitRateKey : 320000,
            AVNumberOfChannelsKey : 2,
            AVSampleRateKey : 44100.0
        ] as [String : Any]
        
        do{
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: recordSettings)
        }catch let error as NSError{
            print("Error-initRecord : \(error)")
        }
        
        audioRecorder.delegate = self
        
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        
        slVolume.value = 1.0
        audioPlayer.volume = slVolume.value
        
        endTime.text = convertNSTimeInterval2String(0)
        currentTime.text = convertNSTimeInterval2String(0)
        setPlayButtons(false, pause: false, stop: false)
        
        let session = AVAudioSession.sharedInstance()
        do{
            try session.setCategory(AVAudioSession.Category.playAndRecord)
        }catch let error as NSError{
            print("error-setCategory : \(error)")
        }
        do{
            try session.setActive(true)
        }catch let error as NSError{
            print("Error-setActive : \(error)")
        }
        
    }
    
    func initPlay(){
        do{
            audioPlayer = try AVAudioPlayer(contentsOf: audioFile)
        }catch let error as NSError{
            print("Error-initPlay: \(error)")
        }
        
        slVolume.maximumValue = MAX_VOLUME //슬라이더의 최대볼륨을 상수값으로 초기화
        slVolume.value = 1.0 // 슬라이더의 볼륨을 1.0으로 초기화
        pvProgressPlay.progress = 0 // 프로그래스 뷰의 진행을 0으로 초기화
        
        audioPlayer.delegate = self // audioPlayer의 델리게이트를 self
        audioPlayer.prepareToPlay() // prepareToPlay()를 실행
        audioPlayer.volume = slVolume.value // audioPlayer의 볼륨을 방금 앞에서 초기화한 슬라이더의 볼륨값 1.0으로 초기화
        endTime.text = convertNSTimeInterval2String(audioPlayer.duration) // 오디오 파일의 재생 시간인 audioPlayer.duration값을 함수를 이용해 출력
        currentTime.text = convertNSTimeInterval2String(0) // 00:00가 출력
//        btnPlay.isEnabled = true //초기화 상태에서 플레이버튼 활성화
//        btnPause.isEnabled = false // 초기화 상태에서 일시정지버튼 비활성화
//        btnStop.isEnabled = false // 초기화 상태에서 정지버튼 비활성화
        setPlayButtons(true, pause: false, stop: false) //초기화 상태에서 플레이버튼 활성화, 일시정지버튼 비활성화, 정지버튼 비활성화
    }
    
    func setPlayButtons(_ play: Bool, pause: Bool, stop: Bool) {
        btnPlay.isEnabled = play
        btnPause.isEnabled = pause
        btnStop.isEnabled = stop
    }
    
    func convertNSTimeInterval2String(_ time:TimeInterval) -> String{
        let min = Int(time/60) //시간을 60으로 나눠서 min에 저장
        let sec = Int(time.truncatingRemainder(dividingBy: 60)) // time값을 60으로 나눈 나머지 값을 정수값으로 변환하여 상수 sec에 초기화
        let strTime = String(format: "%02d:%02d", min, sec) // 이 두 값을 활용해 "%02d:%02d"형태의 문자열로 변환해 상수값에 초기화
        return strTime
    }
    
    @IBAction func btnPlayAction(_ sender: Any) {
        audioPlayer.play()
        setPlayButtons(false, pause: true, stop: true)
        ProgressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timePlayerSelector, userInfo: nil, repeats: true)
    }
    
    @objc func updatePlayTime(){
        currentTime.text = convertNSTimeInterval2String(audioPlayer.currentTime) // 재생시간인 audio.currentTime을 레이블에 나타낸다
        pvProgressPlay.progress = Float(audioPlayer.currentTime / audioPlayer.duration) // 프로그레스 뷰의 진행상황에 현재시간을 duration으로 나눈 값으로 표시한다
        
        endTime.text = convertNSTimeInterval2String(audioPlayer.duration - audioPlayer.currentTime)
    }
    @IBAction func btnPauseAction(_ sender: Any) {
        audioPlayer.pause()
        setPlayButtons(true, pause: false, stop: true)
    }
    @IBAction func btnStopAction(_ sender: Any) {
        audioPlayer.stop()
        audioPlayer.currentTime = 0 // 오디오를 정지하면 현재시간을 0으로 한다
        currentTime.text = convertNSTimeInterval2String(0) // 재생시간을 00:00으로 한다
        endTime.text = convertNSTimeInterval2String(audioPlayer.duration)
        pvProgressPlay.progress = Float(0)
        setPlayButtons(true, pause: false, stop: false)
        ProgressTimer.invalidate() //타이머 무효화
        
    }
    @IBAction func slChangeVolume(_ sender: Any) {
        audioPlayer.volume = slVolume.value
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        ProgressTimer.invalidate()
        setPlayButtons(true, pause: false, stop: false)
    }
    @IBAction func onRecordMode(_ sender: UISwitch) {
        
        if sender.isOn{
            audioPlayer.stop()
            audioPlayer.currentTime = 0
            recordTime!.text = convertNSTimeInterval2String(0)
            isRecordMode = true
            recordTime.isEnabled = true
            onRecord.isEnabled = true
            
        } else{
            isRecordMode = false
            recordTime.isEnabled = false
            onRecord.isEnabled = false
            recordTime.text = convertNSTimeInterval2String(0)
        }
        selectAudioFile()
        
        if !isRecordMode {
            initPlay()
        }else{
            initRecord()
        }
        
    }
    @IBAction func btnRecord(_ sender: UIButton) {
        
        if sender.titleLabel?.text == "Record" {
            audioRecorder.record()
            sender.setTitle("Stop", for: UIControl.State())
            ProgressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: timeRecordSelector, userInfo: nil, repeats: true)
        } else {
            audioRecorder.stop()
            ProgressTimer.invalidate()
            sender.setTitle("Record", for: UIControl.State())
            btnPlay.isEnabled = true
            initPlay()
        }
    }
    @objc func updateRecordTime(){
        recordTime.text = convertNSTimeInterval2String(audioRecorder.currentTime)
    }
}

