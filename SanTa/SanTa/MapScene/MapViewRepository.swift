//
//  MapViewRepository.swift
//  SanTa
//
//  Created by shin jae ung on 2021/11/01.
//

import Foundation

protocol MapViewRepository {
    func fetchMountains(completion: @escaping (Result<[MountainEntity], Error>) -> Void)
    func fetchMapOption(key: Settings, completion: @escaping (Result<Map, Error>) -> Void)
}

class DefaultMapViewRespository {
    enum JSONDecodeError: Error {
        case decodingFailed
    }
    
    enum userDefaultsError: Error {
        case notExists
    }
    
    enum optionError: Error {
        case notExists
    }
    
    private let mountainExtractor: MountainExtractor
    private let settingsStorage: UserDefaultsStorage
    private let coreDataMountainStorage: CoreDataMountainStorage
    
    init(mountainExtractor: MountainExtractor, userDefaultsStorage: UserDefaultsStorage, coreDataMountainStorage: CoreDataMountainStorage) {
        self.mountainExtractor = mountainExtractor
        self.settingsStorage = userDefaultsStorage
        self.coreDataMountainStorage = coreDataMountainStorage
    }
}

extension DefaultMapViewRespository: MapViewRepository {
    func fetchMountains(completion: @escaping (Result<[MountainEntity], Error>) -> Void) {
        self.mountainExtractor.extract { result in
            switch result {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let dataAsset):
                guard let decodedObjects = try? JSONDecoder().decode([MountainEntity].self, from: dataAsset.data) else {
                    return completion(.failure(JSONDecodeError.decodingFailed))
                }
                completion(.success(decodedObjects))
            }
        }
        
        self.coreDataMountainStorage.fetch { result in
            switch result {
            case .failure(let error):
                return completion(.failure(error))
            case .success(let mountainEntityMOs):
                var mountainEntities: [MountainEntity] = []
                mountainEntityMOs.forEach{ MO in
                    let mountain = MountainEntity.MountainDetail(
                        mountainName: MO.name ?? "",
                        mountainRegion: MO.region ?? "",
                        mountainHeight: MO.altitude ?? "",
                        mountainShortDescription: MO.descript ?? ""
                    )
                    let mountainEntity = MountainEntity(
                        id: MO.id ?? UUID(),
                        mountain: mountain,
                        latitude: MO.latitude,
                        longitude: MO.longitude
                    )
                    mountainEntities.append(mountainEntity)
                }
                completion(.success(mountainEntities))
            }
        }
    }
    
    func fetchMapOption(key: Settings, completion: @escaping (Result<Map, Error>) -> Void) {
        self.settingsStorage.string(key: key) { value in
            guard let value = value else {
                completion(.failure(userDefaultsError.notExists))
                return
            }
            guard let map = Map(rawValue: value) else {
                completion(.failure(optionError.notExists))
                return
            }
            let option = MapOption(text: key.title, map: map)
            completion(.success(option.map))
        }
    }
}
