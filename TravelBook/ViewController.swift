//
//  ViewController.swift
//  TravelBook
//
//  Created by Vyacheslav on 24.10.2023.
//

import UIKit
import MapKit
import CoreLocation //Библиотека для работы с гео позицией
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    
    var locationManager = CLLocationManager()//класс, который используется для работы с геолокацией и получения инфо о местоположении устройства
    
    var chosenLatitude = Double()
    var chosenLongitude = Double()
    
    var selectedName = ""
    var selectedId : UUID?
    var selectedComment = ""
    
    var annotationTitle = ""
    var annotationComment = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        if selectedName != "" {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TravelBook")
            
            let idString = selectedId?.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let name = result.value(forKey: "name") as? String {
                            annotationTitle = name
                            if let comment = result.value(forKey: "comment") as? String {
                                annotationComment = comment
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationComment
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                        annotation.coordinate = coordinate
                                        
                                        self.mapView.addAnnotation(annotation)
                                        nameText.text = annotationTitle
                                        commentText.text = annotationComment
                                        
                                        locationManager.stopUpdatingLocation()
                                        
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("can't download data (1)")
            }
            
        } else {
            nameText.text = ""
            commentText.text = ""
        }
        
        mapView.delegate = self //здесь также подключили карту к делегату
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //это свойство, которое определяет точность получения гпс позиции (бест тратит оч много энергии батареи у тф)
        locationManager.requestWhenInUseAuthorization() //тут все понятно( есть еще несколько свойств)
        locationManager.startUpdatingLocation()
        
        mapView.isUserInteractionEnabled = true
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(makePin(gestureRecognizer:))) //долгое нажатие
        gestureRecognizer.minimumPressDuration = 3 //нажатие в 3 сек
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func makePin(gestureRecognizer: UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began { //проверяет начался ли жест долгого нажатия
            let touchedPoint = gestureRecognizer.location(in: self.mapView) //получается точку на экране, где пользователь коснулся в моменте начала жеста
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView) //точка конвертируется в координаты на карте
            chosenLatitude = touchedCoordinates.latitude //засунули широту и долготу в переменные, чтобы потом запихнуть их в дб
            chosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation() //создается объект метки
            annotation.coordinate = touchedCoordinates //туда передаются данные координаты
            annotation.title = nameText.text //заголовок
            annotation.subtitle = commentText.text //надпись
            self.mapView.addAnnotation(annotation) //добавление объекта на карту
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedName == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) // доступ к широте и долготе к первой записи массива(последней добавленной)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05) //разница между шириной и долготой задавая область видимости
            let region = MKCoordinateRegion(center: location, span: span) //видимая область на карте
            
            mapView.setRegion(region, animated: true)
        } else {
            
        }
    }
    
    //метод для кастомки пинов
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        print("suka")
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myPin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.markerTintColor = UIColor.darkGray
            print("debug")
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
            print("not debug")
        }
        
        return pinView
    }
    
    //метод для реализации внутренностей кнопки на вспылвающем окне на аннотации
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                
                if let placemark = placemarks {
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            }
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newPin = NSEntityDescription.insertNewObject(forEntityName: "TravelBook", into: context)
    
        if nameText.text != "" && commentText.text != ""{
            newPin.setValue(nameText.text!, forKey: "name")
            newPin.setValue(commentText.text!, forKey: "comment")
            newPin.setValue(chosenLatitude, forKey: "latitude")
            newPin.setValue(chosenLongitude, forKey: "longitude")
            newPin.setValue(UUID(), forKey: "id")
            do {
                try context.save()
                print("success")
            } catch {
                print("can't save (1)")
            }
        } else {
            print("no!")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("savedData"), object: nil)
        self.navigationController?.popViewController(animated: true)
        
    }
    
}

