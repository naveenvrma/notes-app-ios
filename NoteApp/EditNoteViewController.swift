//
//  EditNoteViewController.swift
//  NoteApp
//
//  Created by KsjLsh on 2020/6/15.
//  Copyright © 2020 KsjLsh. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation
import CoreLocation
class EditNoteViewController: UIViewController,AVAudioRecorderDelegate {
    @IBOutlet weak var titleField: UITextField!
       @IBOutlet weak var infoView: UITextView!
       @IBOutlet weak var photoButton: UIButton!
       
       @IBOutlet weak var recordButton: UIButton!
       @IBOutlet weak var mapView: MKMapView!
       @IBOutlet weak var addressLabel: UILabel!
       var imagePicker: ImagePicker!
       var bPhotoSelected = false
       var recordingSession: AVAudioSession!
       var audioRecorder: AVAudioRecorder!
       var bAudioRecorded = false
       var nNow = 0
       
       
       
    
        var dicNote:NSDictionary!
        var savedArray:NSMutableArray!
        var nIndex:Int!
    
        var previousLocation :CLLocation?
        var locationManager = CLLocationManager()
    
        let regionInMeters : Double = 10000
    override func viewDidLoad() {
    
        super.viewDidLoad()
        checkLocationServices()
        mapView.delegate = self
        for index in 0..<savedArray.count {
            let dicIndex = savedArray.object(at: index) as? NSDictionary
            let strTitle = dicIndex!["title"] as! String
            let strCurrentTitle = dicNote["title"] as! String
            if strTitle == strCurrentTitle {
                nIndex = index
                break
            }
        }
        
        titleField.text = dicNote!["title"] as? String
        infoView.text = dicNote!["infor"] as? String
        addressLabel.text = dicNote!["address"] as? String
        let strImage = (dicNote!["photoUrl"] as? String)!
        if let image = getSavedImage(named: strImage) {
            // do something with image
            photoButton.setImage(image, for: .normal)
        }
        
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.checkAction))
        self.view.addGestureRecognizer(gesture)
        
        
        self.recordButton.isHidden = true
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        // Do any additional setup after loading the view.
        
        
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.recordButton.isHidden = false
                        
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
        
        nNow = Int(Date().timeIntervalSince1970)
        
        
        
        // Do any additional setup after loading the view.
    }
    func setupLocationManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    func centerViewOnUserLocation(){
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    func checkLocationServices(){
        if CLLocationManager.locationServicesEnabled(){
            setupLocationManager()
            checkLocationAuthorization()
        }else{
            
        }
    }
    func checkLocationAuthorization(){
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            startTrackingUserLocation()
        case .denied:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            break
        case .authorizedAlways:
            break
        }
    }
    func startTrackingUserLocation(){
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
    }
    func getCenterLocation(for mapView: MKMapView) -> CLLocation{
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    @objc func checkAction(sender : UITapGestureRecognizer) {
            // Do what you want
            self.view.endEditing(true)
        }
        @IBAction func recordTapped(_ sender: Any) {
            if audioRecorder == nil {
                startRecording()
            } else {
                finishRecording(success: true)
            }
        }
        func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
            if !flag {
                finishRecording(success: false)
            }
        }
        func finishRecording(success: Bool) {
            audioRecorder.stop()
            audioRecorder = nil

            if success {
                recordButton.setTitle("Tap to Re-record", for: .normal)
                bAudioRecorded = true
            } else {
                recordButton.setTitle("Tap to Record", for: .normal)
                // recording failed :(
            }
        }
        func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }
        func startRecording() {
            let audioFilename = getDocumentsDirectory().appendingPathComponent((dicNote!["audioUrl"] as? String)!)

            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            do {
                audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
                audioRecorder.delegate = self
                audioRecorder.record()

                recordButton.setTitle("Tap to Stop", for: .normal)
            } catch {
                finishRecording(success: false)
            }
        }
        @IBAction func saveClicked(_ sender: Any) {
            if titleField.text == "" || infoView.text == "" {
                return
            }
            
            let edittedNote = NSMutableDictionary()
            edittedNote.setValue(titleField.text, forKey: "title")
            edittedNote.setValue(infoView.text, forKey: "infor")
            edittedNote.setValue(addressLabel.text, forKey: "address")
            edittedNote.setValue(Int(Date().timeIntervalSince1970), forKey: "time")
            edittedNote.setValue(dicNote["audioUrl"] as? String, forKey: "audioUrl")
            edittedNote.setValue(dicNote["photoUrl"] as? String, forKey: "photoUrl")
            
            
            savedArray[nIndex] = edittedNote as NSDictionary
            print(savedArray)
            
            let defaults = UserDefaults.standard
            defaults.setValue(savedArray, forKey: "SavedArray")
            self.navigationController?.popViewController(animated: true)
        }
        @IBAction func photoClicked(_ sender: UIButton) {
            self.imagePicker.present(from: sender)
        }
       
        @IBAction func backClicked(_ sender: Any) {
            self.navigationController?.popViewController(animated: true)
        }
        func saveImage(image: UIImage) -> Bool {
            guard let data = image.jpegData(compressionQuality: 1) ?? image.pngData() else {
                return false
            }
            guard let directory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) as NSURL else {
                return false
            }
            do {
                try data.write(to: directory.appendingPathComponent((dicNote!["photoUrl"] as? String)!)!)
                return true
            } catch {
                print(error.localizedDescription)
                return false
            }
        }

        /*
        // MARK: - Navigation

        // In a storyboard-based application, you will often want to do a little preparation before navigation
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            // Get the new view controller using segue.destination.
            // Pass the selected object to the new view controller.
        }
        */

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension EditNoteViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        self.photoButton.setImage(image, for: .normal)
        bPhotoSelected = saveImage(image: image!)
    }
}
extension EditNoteViewController:CLLocationManagerDelegate{
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else {
//            return
//        }
//        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
//        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
//        mapView.setRegion(region, animated: true)
//
//    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
}
extension EditNoteViewController : MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = getCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        
        guard let previousLocation = self.previousLocation else {
            return
        }
        guard center.distance(from: previousLocation) > 50 else { return }
        self.previousLocation = center
        
        geoCoder.reverseGeocodeLocation(center) { [weak self] (placemarks, error) in
            guard let self = self else {return }
            if let _ = error{
                return
            }
            guard let placemark = placemarks?.first else{
                return
            }
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            let lat = String(center.coordinate.latitude )
            let lon = String(center.coordinate.longitude )
           
                DispatchQueue.main.async {
                    
                    self.addressLabel.text = "\(streetNumber) \(streetName)"
                    
                }
            }
            
        }
        
    }
