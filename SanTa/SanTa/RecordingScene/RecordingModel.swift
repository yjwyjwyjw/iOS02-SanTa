//
//  RecordingModel.swift
//  SanTa
//
//  Created by 김민창 on 2021/11/03.
//

import Foundation
import CoreLocation
import CoreMotion
import Combine

final class RecordingModel: NSObject, ObservableObject {
    @Published private(set) var time = ""
    @Published private(set) var kilometer = "0.00"
    @Published private(set) var altitude = "0"
    @Published private(set) var walk = "0"
    @Published private(set) var gpsStatus = true
    
    private let pedoMeter = CMPedometer()
    private var locationManager = CLLocationManager()
    private var timer: DispatchSourceTimer?
    private var timerIsRunning = false
    private var records: Records?
    private var startDate: Date?
    private var oneKileDate: Date?
    private var currentWalk = 0
    private var currentKilo: Double = 0
    private var maxSpeed: Double = 0
    private var minSpeed: Double = 0
    private var sliceDistance: Double = 1
    private var location = [Location]()
    
    private var currentTime = Date() {
        didSet {
            self.timeCalculation()
//            self.checkPedoMeter()
        }
    }
    
    override init() {
        super.init()
        self.startDate = Date()
        self.oneKileDate = self.startDate
        self.configureTimer()
        self.configureLocationManager()
    }
    
    private func configureTimer() {
        self.timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global())
        self.timer?.schedule(deadline: .now(), repeating: 1)
        self.timer?.setEventHandler(handler: { [weak self] in
            self?.currentTime = Date()
        })
        
        self.resume()
    }
    
    private func configureLocationManager() {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.startUpdatingLocation()
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        self.locationManager.showsBackgroundLocationIndicator = true
        self.locationManager.delegate = self
    }
    
    private func timeCalculation() {
        guard let startDate = self.startDate else { return }
        var elapsedTimeSeconds = 0
        
        elapsedTimeSeconds = Int(self.currentTime.timeIntervalSince(startDate))
        
        guard let records = records else {
            self.timeConverter(elapsedTimeSeconds: elapsedTimeSeconds)
            return
        }

        records.records.forEach {
            elapsedTimeSeconds += Int($0.endTime.timeIntervalSince($0.startTime))
        }
        
        self.timeConverter(elapsedTimeSeconds: elapsedTimeSeconds)
    }
    
    private func timeConverter(elapsedTimeSeconds: Int) {
        let seconds = elapsedTimeSeconds % 60
        let minutes = (elapsedTimeSeconds / 60) % 60
        let hours = (elapsedTimeSeconds / 3600)
        
        self.time = String(format: "%0.2d:%0.2d %0.2d\"", hours, minutes, seconds)
    }
    
    private func checkPedoMeter() {
        guard let date = self.startDate else { return }
        var dates = [Record]()
        if records != nil {
            guard let records = records else { return }
            dates = records.records
        }
        
        dates.append(Record(startTime: date, endTime: self.currentTime, step: 0, distance: 0, locations: [Location]()))
        
        let dispatchGroup = DispatchGroup()
        
        self.currentWalk = 0
        self.currentKilo = 0
        
        dispatchGroup.enter()
        dates.forEach {
            dispatchGroup.enter()
            self.pedoMeter.queryPedometerData(from: $0.startTime, to: $0.endTime) { [weak self] data, error in
                guard let activityData = data,
                      error == nil else { return }
                
                let walk = "\(activityData.numberOfSteps)"
                
                guard let walkNumber = Int(walk) else { return }
                
                self?.currentWalk += walkNumber
                
                guard let distance = activityData.distance else { return }
                let transformatKilometer = Double(truncating: distance) / 1000
                self?.currentKilo += transformatKilometer
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.leave()
        dispatchGroup.notify(queue: .global()) { [weak self] in
            guard let walk = self?.currentWalk else { return }
            
            self?.walk = "\(walk)"
            guard let currentKile = self?.currentKilo else { return }
            let distanceString = String(format: "%.2f", currentKile)
            
            self?.kilometer = "\(distanceString)"
        }
    }
    
    private func calculateSpeed() {
        if self.sliceDistance <= self.currentKilo {
            guard let oneKileDate = self.oneKileDate else {
                self.oneKileDate = self.currentTime
                return
            }
            let elapsedTimeMinutes = Double(self.currentTime.timeIntervalSince(oneKileDate))/60
            let speed: Double = 1000/elapsedTimeMinutes
            
            if speed > self.maxSpeed {
                self.maxSpeed = speed
                self.oneKileDate = self.currentTime
            }
            
            if speed < self.minSpeed {
                self.minSpeed = speed
                self.oneKileDate = self.currentTime
            }
        }
    }
    
    private func appendRecord() {
        guard let startdate = self.startDate else { return }
        let record = Record(startTime: startdate,
                            endTime: self.currentTime,
                            step: self.currentWalk,
                            distance: self.currentKilo,
                            locations: self.location)
        
        guard self.records != nil else {
            self.records = Records(title: "", records: [record], assetIdentifiers: [String]())
            return
        }
        
        self.records?.add(record: record)
    }
    
    private func checkAuthorizationStatus() {
        switch self.locationManager.authorizationStatus{
        case .authorizedWhenInUse, .authorizedAlways:
            self.gpsStatus = true
        default:
            self.gpsStatus = false
        }
    }
    
    func pause() {
        guard self.timerIsRunning == true else { return }
        
        self.timerIsRunning = false
        self.appendRecord()
        self.timer?.suspend()
        self.locationManager.stopUpdatingLocation()
        self.startDate = nil
    }
    
    func resume() {
        guard self.timerIsRunning == false else { return }
        
        self.checkAuthorizationStatus()
        
        guard self.gpsStatus == true else { return }
        
        self.timerIsRunning = true
        self.timer?.resume()
        self.locationManager.startUpdatingLocation()
        self.startDate = Date()
        self.location = [Location]()
    }
    
    func cancel() -> Records? {
        guard let records = self.records else { return nil }
    
        if !self.timerIsRunning {
            self.timer?.resume()
        }
        
        self.timer?.cancel()
        self.timer = nil
        self.locationManager.stopUpdatingLocation()
        
        return records
    }
}

extension RecordingModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            location.append(Location(latitude: Double(lastLocation.coordinate.latitude),
                                     longitude: Double(lastLocation.coordinate.longitude),
                                     altitude: Double(lastLocation.altitude)))
            self.checkPedoMeter()
            altitude = "\(Int(lastLocation.altitude))"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.gpsStatus = false
    }
}
