//
//  TableViewController.swift
//  Mianbot
//
//  Created by O YANO on 2017/2/21.
//  Copyright © 2017年 hyalineheaven. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class TableViewController: UITableViewController {

    var mapItems = [MKMapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as! CustomCell
        let table = mapItems[indexPath.row].placemark.addressDictionary as NSDictionary? as? [AnyHashable: Any] ?? [:]
        let addr = table["FormattedAddressLines"] as! NSArray?
        cell.title.text = mapItems[indexPath.row].name
        cell.address.text = addr?.lastObject as? String
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "TableToMapSegue", sender: indexPath.row)
    }
    
    // MARK : - Peform segue to MapViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TableToMapSegue" {
            if let destinationVC = segue.destination as? MapViewController {
                destinationVC.mapItem = mapItems[(sender as! Int)]
            }
        }
    }
}
