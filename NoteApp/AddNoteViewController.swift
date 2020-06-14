//
//  AddNoteViewController.swift
//  NoteApp
//
//  Created by KsjLsh on 2020/6/15.
//  Copyright © 2020 KsjLsh. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation
import CoreLocation
public protocol ImagePickerDelegate: class {
    func didSelect(image: UIImage?)
}

open class ImagePicker: NSObject {

    private let pickerController: UIImagePickerController
    private weak var presentationController: UIViewController?
    private weak var delegate: ImagePickerDelegate?

    public init(presentationController: UIViewController, delegate: ImagePickerDelegate) {
        self.pickerController = UIImagePickerController()

        super.init()

        self.presentationController = presentationController
        self.delegate = delegate

        self.pickerController.delegate = self
        self.pickerController.allowsEditing = true
        self.pickerController.mediaTypes = ["public.image"]
    }

    private func action(for type: UIImagePickerController.SourceType, title: String) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(type) else {
            return nil
        }

        return UIAlertAction(title: title, style: .default) { [unowned self] _ in
            self.pickerController.sourceType = type
            self.presentationController?.present(self.pickerController, animated: true)
        }
    }

    public func present(from sourceView: UIView) {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        if let action = self.action(for: .camera, title: "Take photo") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .savedPhotosAlbum, title: "Camera roll") {
            alertController.addAction(action)
        }
        if let action = self.action(for: .photoLibrary, title: "Photo library") {
            alertController.addAction(action)
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController.popoverPresentationController?.sourceView = sourceView
            alertController.popoverPresentationController?.sourceRect = sourceView.bounds
            alertController.popoverPresentationController?.permittedArrowDirections = [.down, .up]
        }

        self.presentationController?.present(alertController, animated: true)
    }

    private func pickerController(_ controller: UIImagePickerController, didSelect image: UIImage?) {
        controller.dismiss(animated: true, completion: nil)

        self.delegate?.didSelect(image: image)
    }
}

extension ImagePicker: UIImagePickerControllerDelegate {

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.pickerController(picker, didSelect: nil)
    }

    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.editedImage] as? UIImage else {
            return self.pickerController(picker, didSelect: nil)
        }
        self.pickerController(picker, didSelect: image)
    }
}

extension ImagePicker: UINavigationControllerDelegate {

}
class AddNoteViewController: UIViewController,AVAudioRecorderDelegate {

    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var infoView: UITextView!
    @IBOutlet weak var photoButton: UIButton!
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var addressLabel: UILabel!
    
    var previousLocation :CLLocation?
    
    var imagePicker: ImagePicker!
    var bPhotoSelected = false
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var bAudioRecorded = false
    var nNow = 0
    
    var locationManager = CLLocationManager()
    
    let regionInMeters : Double = 10000
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        checkLocationServices()
        mapView.delegate = self
        
        
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
        let audioFilename = getDocumentsDirectory().appendingPathComponent(String(format: "%d_recording.m4a", nNow))

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
        if titleField.text == "" || infoView.text == "" || !bAudioRecorded || !bPhotoSelected || addressLabel.text == "" {
            return
        }
        
        let dicNote = NSMutableDictionary()
        dicNote.setValue(titleField.text, forKey: "title")
        dicNote.setValue(infoView.text, forKey: "infor")
        dicNote.setValue(addressLabel.text, forKey: "address")
//        dicNote.setValue(String(currentLoc.coordinate.latitude), forKey: "lat")
//        dicNote.setValue(String(currentLoc.coordinate.longitude), forKey: "lng")
        dicNote.setValue(Int(Date().timeIntervalSince1970), forKey: "time")
        dicNote.setValue(String(format: "%d_recording.m4a", nNow), forKey: "audioUrl")
        dicNote.setValue(String(format: "%d_photo.png", nNow), forKey: "photoUrl")
        
        let defaults = UserDefaults.standard
        
        if defaults.value(forKey: "SavedArray") != nil { // array is already existing
            let savedData = defaults.value(forKey: "SavedArray") as! NSMutableArray
            let savedArray = savedData.mutableCopy() as! NSMutableArray
            savedArray.add(dicNote)
            print(savedArray)
            DispatchQueue.main.async {
                defaults.setValue(savedArray, forKey: "SavedArray")
            }
            
            
        } else { // first time, so array is not existing
            let savedArray = NSMutableArray()
            savedArray.add(dicNote)
            print(savedArray)
            DispatchQueue.main.async {
                defaults.setValue(savedArray, forKey: "SavedArray")
            }
        }
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
            try data.write(to: directory.appendingPathComponent(String(format: "%d_photo.png", nNow))!)
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

}
extension AddNoteViewController: ImagePickerDelegate {

    func didSelect(image: UIImage?) {
        self.photoButton.setImage(image, for: .normal)
        bPhotoSelected = saveImage(image: image!)
    }
}
extension AddNoteViewController:CLLocationManagerDelegate{
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
extension AddNoteViewController : MKMapViewDelegate{
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

