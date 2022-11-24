//
//  PhotoAlbumViewController.swift
//  virtualToursitApp
//
//  Created by MACBOOK PRO on 11/24/22.
//
import Foundation
import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate, UICollectionViewDelegate {
    
    var pin : Pin!
    var photo: [Photo]! = []
    
    var dataController : DataController!
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    @IBOutlet weak var collectionFlowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var photoMapView: MKMapView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photoMapView.delegate = self
        setUpCollectionView()
        setupMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultController()
        collectionView.reloadData()
        getPhotos()
    }
    
    fileprivate func setupMap() {
        let annotation = MKPointAnnotation()
        annotation.coordinate.longitude = pin.longitude
        annotation.coordinate.latitude = pin.latitude
        photoMapView.addAnnotation(annotation)
        let coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
        
        // indicates desired zoom level of the map
        let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        photoMapView.setRegion(region, animated: true)
    }
    
    func getPhotos(){
        
        if fetchedResultsController.fetchedObjects?.count == 0 {
            FlickrDataClient.getPhotos(latitude: pin.latitude, longitude: pin.longitude) { response, error in
                
                if error == nil && response?.photos.photo != nil {
                    print("album start saving")
                    guard let response = response
                    else {return
                        print("has been returned")
                    }
                    for image in response.photos.photo {
                        print("image has been returned")
                        let photo = Photo(context: self.dataController.viewContext)
                        photo.creationDate = Date()
                        photo.imageURL =
                        "https://live.staticflickr.com/\(image.server)/\(image.id)_\(image.secret).jpg"
                        photo.pin = self.pin
                    }
                    
                    do {
                        try self.dataController.viewContext.save()
                    } catch {
                        fatalError("Unable to save photos: \(error.localizedDescription)")
                    }
                    print("album currently been saved")
                    self.collectionView.reloadData()
                    print("album saved")
                    self.collectionView.reloadData()
                    debugPrint()
                    
                } else {
                    print("No photo downloaded")
                    
                }
            }
        } else {
            return
        }
    }
    
    // fetched result controller
    func setUpFetchedResultController(){
        
        let fetchRequest : NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format : "pin == %@", argumentArray: [self.pin!])
        fetchRequest.predicate = predicate
        
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            
        } catch  {
            fatalError("Request Failed: \(error.localizedDescription)")
        }
        
    }
    
    // collection button action
    @IBAction func collectionButtonTapped(_ sender: Any) {
        
        newCollectionButton.isEnabled = false
        
        if let album = fetchedResultsController.fetchedObjects{
            for photo in album{
                dataController.viewContext.delete(photo)
                
                setUpFetchedResultController()
                
                getPhotos()
                
                newCollectionButton.isEnabled = true
            }
        }
    }
    
    // collections delegates and data source
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        setUpFetchedResultController()
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        
        let photo = fetchedResultsController.object(at : indexPath)
        
        if let url = photo.imageURL {
            if let image = photo.image{
                cell.imageViewCell.image = UIImage(data: image)
                cell.activityIndicator.startAnimating()
            } else {
                FlickrDataClient.downloadPhotos(imageURL: URL(string: url)!) { data, error in
                    cell.activityIndicator.startAnimating()
                    if let data = data{
                        let image = UIImage(data: data)
                        cell.imageViewCell.image = image
                        cell.activityIndicator.stopAnimating()
                        do {
                            photo.image = data
                            try self.dataController.viewContext.save()
                        } catch {
                            fatalError("Unable to save photos: \(error.localizedDescription)")
                        }
                        
                    } else {
                        fatalError("error:\(String(describing: error?.localizedDescription))")
                        
                    }
                }
            }
        } else{
            
            let placeholderImage = UIImage(systemName: "Flickr")
            cell.imageViewCell.image = placeholderImage
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let objectSelected = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(objectSelected)
        
        if var photos = fetchedResultsController.fetchedObjects{
            photos.remove(at: indexPath.row)
        }
        
        // newly added
        collectionView.deleteItems(at: [indexPath])
        
        try? dataController.viewContext.save()
        setUpFetchedResultController()
    }
    
    fileprivate func setUpCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionFlowLayout.scrollDirection = .vertical
        self.collectionView.collectionViewLayout = self.collectionFlowLayout
    }
    
    
    

    
}
