//
//  MapViewController.swift
//  Mianbot
//
//  Created by O YANO on 2017/2/21.
//  Copyright © 2017年 hyalineheaven. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var phone: UILabel!
    @IBOutlet weak var address: UITextView!
    
    
    var mapItem = MKMapItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let table = mapItem.placemark.addressDictionary as NSDictionary? as? [AnyHashable: Any] ?? [:]
        let addr = table["FormattedAddressLines"] as! NSArray?
        
        name.text = mapItem.name
        phone.text = mapItem.phoneNumber
        address.text = addr?.lastObject as? String
        
        let coordinate = mapItem.placemark.coordinate
        let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        
        mapView.addAnnotation(annotation)
        mapView.setRegion(region, animated: true)
        mapView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
