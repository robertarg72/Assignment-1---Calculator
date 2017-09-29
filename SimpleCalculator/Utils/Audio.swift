/*
 * Audio.swift
 * Project: SimpleCalculator
 * Name: Robert Argume
 * StudentID: 300949529
 * Description:
 * Implementation of methods used for playing audio in the App
 */

import Foundation
import AVFoundation

// Variable added to initialize audio in the App
var audioPlayer = AVAudioPlayer()

// Play a sound from a file inside the project
// To be reused anywhere in the App
// From: https://stackoverflow.com/questions/43715285/xcode-swift-adding-sound-effects-to-launch-screen
func playSound(file:String, ext:String) -> Void {
    do {
        let url = URL.init(fileURLWithPath: Bundle.main.path(forResource: file, ofType: ext)!)
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer.prepareToPlay()
        audioPlayer.play()
    } catch let error {
        NSLog(error.localizedDescription)
    }
}
