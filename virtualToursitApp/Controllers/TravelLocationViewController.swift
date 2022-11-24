//
//  ViewController.swift
//  virtualToursitApp
//
//  Created by MACBOOK PRO on 11/24/22.
//

import UIKit
import MapKit
import CoreData

class TravelLocationViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    
    
    var dataController : DataController!
    var fetchedResultsController : NSFetchedResultsController<Pin>!
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.isUserInteractionEnabled = true
        setUpFetchResultsController()
        loadZoomLevel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dropPin()
        setUpFetchResultsController()
        saveZoomLevel()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    fileprivate func setUpFetchResultsController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        dataController = appDelegate.dataController
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try? fetchedResultsController.performFetch()
        } catch {
            fatalError("Request failed:\(error.localizedDescription)")
        }
    }
    
    func dropPin(){
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(Location(gestureRecognizer:)))
        mapView.addGestureRecognizer(gestureRecognizer)
        
    }
    @objc func Location(gestureRecognizer : UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            self.mapView.addAnnotation(annotation)
            addPin(lat: touchedCoordinates.latitude, long: touchedCoordinates.longitude)
            debugPrint("pin: \(touchedCoordinates.latitude), \(touchedCoordinates.longitude)")
        }
    }
    
    func addPin(lat : Double , long : Double){
        let pin = Pin(context: dataController!.viewContext)
        pin.latitude = lat
        pin.longitude = long
        pin.creationDate = Date()
        do {
            try dataController?.viewContext.save()
        } catch {
            fatalError("Pin cannot be added :\(error.localizedDescription)")
        }
        
        setUpFetchResultsController()
    }
    
    // set map view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: false)
        let latitudeClicked = view.annotation?.coordinate.latitude
        let longitudeClicked = view.annotation?.coordinate.longitude
        
        // segue action
        if let pins = fetchedResultsController.fetchedObjects{
            for pin in pins {
                if pin.latitude == latitudeClicked && pin.longitude == longitudeClicked {
                    if let vc = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as? PhotoAlbumViewController {
                        vc.pin = pin
                        vc.dataController = dataController
                        self.navigationController?.pushViewController(vc, animated: true)
                    }else {
                        fatalError("error!")
                        
                    }
                }
            }
        }
    }
    
    
    func saveZoomLevel(){
        
        UserDefaults.standard.set(mapView.centerCoordinate.latitude, forKey: ZoomImageModel.latitude)
        UserDefaults.standard.set(mapView.centerCoordinate.longitude, forKey: ZoomImageModel.longitude)
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: ZoomImageModel.latitudeDelta)
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: ZoomImageModel.longitudeDelta)
        
    }
    
    func loadZoomLevel(){
        
        guard let longitude = UserDefaults.standard.object(forKey: ZoomImageModel.longitude) as? Double else {return}
        guard let latitude = UserDefaults.standard.object(forKey: ZoomImageModel.latitude) as? Double else {return}
        guard let latitudeDelta = UserDefaults.standard.object(forKey: ZoomImageModel.latitudeDelta) as? Double else {return}
        guard let longitudeDelta = UserDefaults.standard.object(forKey: ZoomImageModel.longitudeDelta) as? Double else {return}
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        
        if let pins = fetchedResultsController.fetchedObjects {
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                mapView.addAnnotation(annotation)
                
            }
        }
        
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveZoomLevel()
    }

}

