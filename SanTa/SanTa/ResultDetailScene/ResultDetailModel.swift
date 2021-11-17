//
//  ResultDetailModel.swift
//  SanTa
//
//  Created by Jiwon Yoon on 2021/11/16.
//

import Foundation
import CoreLocation

struct ResultDetailData {
    let timeStamp: ResultTimeStamp
    let distance: ResultDistance
    let time: ResultTime
//    let pace: ResultPace
    let altitude: ResultAltitude
    let incline: ResultIncline
}

struct ResultTimeStamp {
    let startTime: Date
    let endTime: Date
    let startLocation: Location?
    let endLocation: Location?
    
    init(records: Records) {
        self.startTime = records.records.first?.startTime ?? Date.distantPast
        self.endTime = records.records.last?.endTime ?? Date.distantFuture
        self.startLocation = records.records.first?.locations.first
        self.endLocation = records.records.last?.locations.last
    }
}

struct ResultDistance {
    let total: Double
    let exercise: Double
    let steps: Int
    
    init(records: Records) {
        self.total = records.distances
        self.exercise = records.distances  //??
        self.steps = records.steps
    }
}

struct ResultTime {
    let spent: TimeInterval
    let active: TimeInterval
    let inactive: TimeInterval
    
    init(records: Records) {
        var active: TimeInterval = 0
        var inactive: TimeInterval = 0
        for index in 0..<records.records.count - 1 {
            let startTime = records.records[index].startTime
            let timeBeforeStop = records.records[index].endTime
            let resumeTime = records.records[index+1].startTime
            inactive += resumeTime.timeIntervalSince(timeBeforeStop)
            active += timeBeforeStop.timeIntervalSince(startTime)
        }
        self.active = active
        self.inactive = inactive
        self.spent = active + inactive
    }
}

struct ResultPace {
    let timePerKilometer: TimeInterval
    let fastestPace: TimeInterval
    let slowestPace: TimeInterval
}

struct ResultAltitude {
    let total: Int
    let highest: Int
    let lowest: Int
    let starting: Int
    let ending: Int
    
    init(records: Records) {
        let maxAltitude:Int = Int(records.records.flatMap{$0.locations}.max{ $0.altitude < $1.altitude }?.altitude ?? 0)
        let minAltitude = Int(records.records.flatMap{$0.locations}.min{ $0.altitude < $1.altitude }?.altitude ?? 0)
        let total = Int(maxAltitude - minAltitude)
        let startAltitude = Int(records.records.first?.locations.first?.altitude ?? 0)
        let endAltitude = Int(records.records.last?.locations.last?.altitude ?? 0)
        
        self.total = total
        self.highest = maxAltitude
        self.lowest = minAltitude
        self.starting = startAltitude
        self.ending = endAltitude
    }
}

struct ResultIncline {
    let average: Int
    let highest: Int
    let uphillKilometer: Double
    let downhillKilometer: Double
    let plainKilometer: Double
    
    init(records: Records) {
        var totalIncline: Double = 0
        var steepest: Double = 0
        var uphillDistance: Double = 0
        var downHillDistance: Double = 0
        var plainDistance: Double = 0
        
        var locations: [Location] = []
        for record in records.records {
            locations.append(contentsOf: record.locations)
        }
        
        for index in 0..<locations.count - 1 {
            let current = CLLocation(latitude: locations[index].latitude, longitude: locations[index].longitude)
            let next = CLLocation(latitude: locations[index+1].latitude, longitude: locations[index+1].longitude)
            let distanceDelta = current.distance(from: next)
            let altitudeDelta = next.altitude - current.altitude
            let incline = atan(altitudeDelta / distanceDelta)
            totalIncline += incline
            steepest = steepest < incline ? incline : steepest
            uphillDistance += altitudeDelta > 0 ? abs(distanceDelta) : 0
            downHillDistance += altitudeDelta < 0 ? abs(distanceDelta) : 0
            plainDistance += altitudeDelta == 0 ? abs(distanceDelta) : 0
        }
        
        self.average = Int(totalIncline / Double(locations.count - 1))
        self.highest = Int(steepest)
        self.uphillKilometer = uphillDistance / 1000
        self.downhillKilometer = downHillDistance / 1000
        self.plainKilometer = plainDistance / 1000
    }
}
