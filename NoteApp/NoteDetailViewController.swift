//
//  NoteDetailViewController.swift
//  NoteApp
//
//  Created by KsjLsh on 2020/6/15.
//  Copyright © 2020 KsjLsh. All rights reserved.
//

import UIKit
import AVFoundation

class NoteDetailViewController: UIViewController,AVAudioPlayerDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var latLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var ivPhoto: UIImageView!
    var noteData:NSDictionary?
    var audioPlayer : AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = noteData!["title"] as? String
        infoLabel.text = noteData!["infor"] as? String
        let nTime = noteData!["time"] as? Int
        
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let dateString = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(nTime!)) as Date)
        timeLabel.text = dateString
        

        latLabel.text = noteData!["address"] as? String
        
        
        
        
        let strImage = (noteData!["photoUrl"] as? String)!
        if let image = getSavedImage(named: strImage) {
            // do something with image
            ivPhoto.image = image
        }
        
        
        

       
            audioPlayer?.play()
        
        // Do any additional setup after loading the view.
    }
    func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getFileURL() -> URL {
        let path = getDocumentsDirectory().appendingPathComponent((noteData!["audioUrl"] as? String)!)
        return path as URL
    }
    
    @IBAction func playClicked(_ sender: UIButton) {
        if (sender.titleLabel?.text == "Tap to Play"){
            
            sender.setTitle("Tap to Stop", for: .normal)
            preparePlayer()
            audioPlayer!.play()
        } else {
            audioPlayer!.stop()
            sender.setTitle("Tap to Play", for: .normal)
        }
    }
    func preparePlayer() {
        var error: NSError?
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: getFileURL() as URL)
        } catch let error1 as NSError {
            error = error1
            audioPlayer = nil
        }
        
        if let err = error {
            print("AVAudioPlayer error: \(err.localizedDescription)")
        } else {
            audioPlayer!.delegate = self
            audioPlayer!.prepareToPlay()
            audioPlayer!.volume = 10.0
        }
    }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        
        playButton.setTitle("Tap to Play", for: .normal)
    }
    @IBAction func backClicked(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
