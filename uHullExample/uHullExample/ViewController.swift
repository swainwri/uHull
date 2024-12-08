//
//  ViewController.swift
//  uHullExample
//
//  Created by Steve Wainwright on 07/12/2024.
//
//  Borrowed from Sany Maamari on 02/04/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import MapKit
import uHull

class ViewController: UIViewController, MKMapViewDelegate, UITextFieldDelegate {
    let minimumZoomArc: CLLocationDegrees = 0.014 //approximately 1 miles (1 degree of arc ~= 69 miles)
    let annotationRegionFactorPad: CLLocationDegrees = 1.15
    let maxDegreesArc: CLLocationDegrees = 360

    var arrayOfStations: [Station] = [Station]()
    var coordsOfStations: [CLLocationCoordinate2D] = [CLLocationCoordinate2D]()
    var hull = uHull.Alpha_Shape()
    var alpha: Double = 1.5

    @IBOutlet weak var slider: UISlider?
    @IBOutlet weak var map: MKMapView?
    @IBOutlet weak var concavityLabel: UILabel?
    @IBOutlet weak var multiplierTextField: UITextField?

    override func viewDidLoad() {
        super.viewDidLoad()
        map?.delegate = self
        multiplierTextField?.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewWillAppear(_ animated: Bool) {
        debugConnectionForParis()
    }

    override func viewDidAppear(_ animated: Bool) {
        concavityLabel?.text = (floor(alpha * 1000) / 1000).description
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sliderValueChanged(sender: AnyObject) {
        drawPolygon()
    }

    @IBAction func multiplierValueChanged(sender: AnyObject) {
        drawPolygon()
    }

    @IBAction func showAnnotations() {
        if self.map?.annotations.count == 0 {
            self.map?.addAnnotations(arrayOfStations)
        }
    }

    @IBAction func hideAnnotations() {
        if (self.map?.annotations.count)! > 0 {
            self.map?.removeAnnotations((self.map?.annotations)!)
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        drawPolygon()
        return true
    }

    func debugConnectionForParis() {
        let filePath = Bundle.main.path(forResource: "paris", ofType: "json")
        if filePath == nil {
            print("no file")
            return
        }
        do {
            let fileContent = try String.init(contentsOfFile: filePath!, encoding: String.Encoding.utf8)
            let d = fileContent.data(using: String.Encoding.utf8)
            if d == nil {
                print("unable to get data")
                return
            }
            self.fetchData(d!)
        } catch {
            print(error)
        }
    }

    func fetchData(_ data: Data) {
        fetch(data: data)
        coordsOfStations = arrayOfStations.map { (stat: Station) -> CLLocationCoordinate2D in
            return stat.coordinate
        }

        self.map?.addAnnotations(arrayOfStations)
        let mapRect: MKMapRect? = self.createMapRect(with: arrayOfStations)
        self.zoomMapViewToFitAnnotations(mapRect: mapRect!, count: (self.map?.annotations.count)!, animated: true)
        drawPolygon()
    }

    func drawPolygon() {
        self.map?.removeOverlays((self.map?.overlays)!)
        
        alpha = getSliderValue()
        concavityLabel?.text = (floor(alpha * 1000) / 1000).description
        
        if var polygons = hull.getAlphaShapePolygons(coordinates_points: coordsOfStations.map({ ASPoint(x: Double($0.latitude), y:Double($0.longitude)) }), alpha: alpha, distance: Geometry().euclidean_distance) {
            polygons = polygons.sorted(by: { $0.count > $1.count })
            var i: Int = 0
            for polygon in polygons {
                let polyline = MKPolyline(coordinates: polygon.map( { CLLocationCoordinate2D(latitude: $0.x, longitude: $0.y) } ), count: polygon.count)
                polyline.title = "Polygon \(i + 1)"
                i += 1
                self.map?.addOverlay(polyline)
            }
        }
    }

    func fetch(data: Data) {
        var array: [Station] = [Station].init()
        do {
            let tempArrayOfStation = (try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)) as? [Any]
            if tempArrayOfStation == nil || tempArrayOfStation!.count == 0 {
                arrayOfStations = array
            }

            for stat in tempArrayOfStation! where stat is [String: Any] {
                let myStat = stat as? [String: Any]
                let station: Station? = Station(dictionary: myStat!)
                if station != nil {
                    array.append(station!)
                }
            }
            arrayOfStations = array
        } catch {
            print(error)
        }
    }

    func createMapRect(with annotations: [Station]) -> MKMapRect? {
        let count = annotations.count
        if count == 0 {
            return nil
        }
        var points: [MKMapPoint] = [MKMapPoint].init()
        for anno in annotations {
            points.append(MKMapPoint(anno.coordinate))
        }

        return MKPolygon(points: points, count: points.count).boundingMapRect
    }

    func zoomMapViewToFitAnnotations(mapRect: MKMapRect, count: Int, animated: Bool) {
        var region: MKCoordinateRegion = MKCoordinateRegion(mapRect)
        self.customSetRegion(region: &region, count: count, animated: animated)
    }

    func customSetRegion(region: inout MKCoordinateRegion, count: Int, animated: Bool) {
        // add padding so pins aren't scrunched on the edges
        region.span.latitudeDelta *= annotationRegionFactorPad
        region.span.longitudeDelta *= annotationRegionFactorPad

        // but padding can't be bigger than the world
        if region.span.latitudeDelta > maxDegreesArc {
            region.span.latitudeDelta = maxDegreesArc
        }
        if region.span.longitudeDelta > maxDegreesArc {
            region.span.longitudeDelta = maxDegreesArc
        }

        // and don't zoom in stupid-close on small samples
        if region.span.latitudeDelta < minimumZoomArc {
            region.span.latitudeDelta = minimumZoomArc
        }
        if region.span.longitudeDelta < minimumZoomArc {
            region.span.longitudeDelta = minimumZoomArc
        }

        // and if there is a sample of 1 we want the max zoom-in instead of max zoom-out
        if count == 1 {
            region.span.latitudeDelta = minimumZoomArc
            region.span.longitudeDelta = minimumZoomArc
        }
        self.map?.setRegion(region, animated: animated)
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer: MKPolylineRenderer = MKPolylineRenderer.init(overlay: overlay)

        let lineWidth: CGFloat = overlay.title == "Polygon 1" ? 8 : 4
        let lineColor: UIColor = overlay.title == "Polygon 1" ? UIColor.blue : UIColor.red
        renderer.fillColor = lineColor
        renderer.strokeColor = lineColor
        renderer.lineWidth = lineWidth

        return renderer
    }

    func getSliderValue() -> Double {
        if let text = multiplierTextField?.text,
           let multiplier = Double(text),
           let sliderValue = slider?.value,
           multiplier > 0 {
            return multiplier * Double(sliderValue)
        }
        else {
            return 1.5
        }
    }
}
