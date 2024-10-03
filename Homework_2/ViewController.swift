//
//  ViewController.swift
//  Homework_2
//
//  Created by Sofya Avtsinova on 01.10.2024.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        var veh1 = Vehicle(make: "vehicle",
                           model: "1",
                           year: 2012,
                           capacity: 20,
                           types: [.bulk(packaged: true), .perishable(temperature: 1...10)],
                           fuel: 100)
        
        var truck1 = Truck(make: "truck",
                           model: "1",
                           year: 2020,
                           capacity: 10,
                           trailerCapacity: 20,
                           types: [.bulk(packaged: true), .fragile(moistureProtection: true)],
                           trailerTypes: [.perishable(temperature: -2...2)],
                           fuel: 100)
        
        var myCargo = Cargo(description: "cement", weight: 10, type: .bulk(packaged: true))
        var myTruckCargo = Cargo(description: "chocolate", weight: 10, type: .perishable(temperature: 0...10))
        var myTruckCargo2 = Cargo(description: "cheese", weight: 10, type: .perishable(temperature: -1...5))
        var myWrongCargo = Cargo(description: "glass", weight: 5, type: .fragile(moistureProtection: false))
        
        veh1.loadCargo(cargo: myCargo)
        veh1.loadCargo(cargo: myTruckCargo)
        truck1.loadCargo(cargo: myWrongCargo)
        
        var fleet = Fleet()
        fleet.addVehicle(veh1)
        fleet.addVehicle(truck1)
        
        fleet.printInfo()
        print("Result canGo: \(fleet.canGo(cargos: [myCargo, myTruckCargo, myTruckCargo2, myWrongCargo], path: 10))")
    }
}

class Vehicle {
    let make: String
    let model: String
    let year: Int
    var capacity: Int
    let permittedCargoTypes: [CargoType]?
    var currentLoad: Int?
    var fuel: Int
    
    init(make: String,
         model: String,
         year: Int,
         capacity: Int,
         types: [CargoType],
         fuel: Int) {
        self.make = make
        self.model = model
        self.year = year
        self.capacity = capacity
        self.permittedCargoTypes = types
        self.fuel = fuel
    }
    
    // проверяем, можно ли перевозить груз в этом ТС
    func cargoIsPermitted(storage: [CargoType]?, cargo: CargoType) -> Bool {
        guard let storage else {
            return true
        }
        
        return storage.contains(where: { $0 == cargo })
    }
    
    func loadCargo(cargo: Cargo?) {
        guard let cargo else {
            return
        }
        
        if cargoIsPermitted(storage: permittedCargoTypes, cargo: cargo.type) {
            addWeight(weight: cargo.weight)
        } else {
            print("Cannot transport this type")
            return
        }
    }
    
    func unloadCargo() {
        currentLoad = nil
    }
}

private extension Vehicle {
    func addWeight(weight: Int) {
        let newLoad = currentLoad ?? 0 + weight
        
        if newLoad < capacity {
            self.currentLoad = newLoad
        } else {
            print("Not enough capacity")
        }
    }
}

class Truck: Vehicle {
    let trailerAttached: Bool
    var trailerCapacity: Int?
    let trailerTypes: [CargoType]?
    
    init(make: String,
         model: String,
         year: Int,
         capacity: Int,
         trailerCapacity: Int?,
         types: [CargoType],
         trailerTypes: [CargoType]?,
         fuel: Int) {
        self.trailerCapacity = trailerCapacity
        self.trailerAttached = trailerCapacity != nil
        self.trailerTypes = trailerTypes
        super.init(make: make, model: model, year: year, capacity: capacity, types: types, fuel: fuel)
    }

    override func loadCargo(cargo: Cargo?) {
        guard let cargo else {
            return
        }
        
        addWeight(weight: cargo.weight,
                  vehicleIsPermitted: cargoIsPermitted(storage: permittedCargoTypes, cargo: cargo.type),
                  trailerIsPermitted: cargoIsPermitted(storage: trailerTypes, cargo: cargo.type))
    }
}

private extension Truck {
    func addWeight(weight: Int, vehicleIsPermitted: Bool, trailerIsPermitted: Bool) {
        let newLoad = currentLoad ?? 0 + weight
        let permittedCapacity = 
        (vehicleIsPermitted ? capacity : 0) +
        (trailerIsPermitted ? trailerCapacity ?? 0 : 0)

        if newLoad < permittedCapacity {
            self.currentLoad = newLoad
        } else {
            !vehicleIsPermitted && !trailerIsPermitted ?
            print("Cannot transport this type") :
            print("Not enough capacity")
        }
    }
}

struct Cargo {
    var description: String
    var weight: Int
    var type: CargoType
    
    init?(description: String, weight: Int, type: CargoType) {
        if weight > 0 {
            self.weight = weight
        } else {
            return nil
        }
        self.description = description
        self.type = type
    }
}

//Ассоциированые параметры для типов грузов:
//хрупкое: необходима ли защита от влаги
//скоропортящееся: температурный режим
//сыпучее: упакован груз или нет
enum CargoType {
    case fragile(moistureProtection: Bool)
    case perishable(temperature: ClosedRange<Int>)
    case bulk(packaged: Bool)
}

//Проверка, может ли ТС перевозить этот груз на основе ассоциированных значений:
//хрупкое: ТС должно иметь защиту от влаги, если это необходимо (иначе не должно)
//сыпучее: ТС может перевозить либо ТОЛЬКО упакованный груз, либо ТОЛЬКО не упакованный
//скоропортящееся: ТС должно иметь возможность поддерживать необходимый температурный режим
extension CargoType: Equatable {
    static func == (lhs: CargoType, rhs: CargoType) -> Bool {
        switch (lhs, rhs) {
        case (.fragile(let protection1), .fragile(let protection2)):
            protection1 == protection2
        case (.perishable(let temperature1), .perishable (let temperature2)):
            temperature1.contains(temperature2.lowerBound) || temperature1.contains(temperature2.upperBound)
        case (.bulk(let packaged1), .bulk(let packaged2)):
            packaged1 == packaged2
        default:
            false
        }
    }
}


class Fleet {
    var vehicles: [Vehicle] = []
    let consumption = 0.2
    
    struct GeneralVehicalCapacity {
        var carCapacity : Int
        var trailerCapacity : Int?
    }

    func addVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
    }
    
    func totalCapacity() -> Int {
        vehicles.reduce(0, {$0 + $1.capacity + (($1 as? Truck)?.trailerCapacity ?? 0)})
    }
    
    func totalCurrentLoad() -> Int {
        vehicles.reduce(0, {$0 + ($1.currentLoad ?? 0)})
    }
    
    func printInfo() {
        print("Vehicles in fleet: \n")
        vehicles.forEach {
            print("Mark: \($0.make)")
            print("Model: \($0.model)")
            print("Year: \($0.year)")
            print("Capacity: \($0.capacity) + (\(($0 as? Truck)?.trailerCapacity ?? 0))")
            print("Current load: \($0.currentLoad ?? 0)")
            print("Fuel: \($0.fuel) \n")
        }
        
        print("Total capacity: \(totalCapacity())")
        print("Total current load: \(totalCurrentLoad()) \n")
    }

    func canGo(cargos: [Cargo?], path: Int) -> Bool {
        let filteredCargos = cargos.compactMap { $0 }

        let filteredVehicles = vehicles.filter({(Double($0.fuel) * consumption) / 2.0 >= Double(path)})
        
        var vehiclesCapacities: [GeneralVehicalCapacity] = filteredVehicles
            .map {GeneralVehicalCapacity(carCapacity: $0.capacity,
                                         trailerCapacity: ($0 as? Truck)?.trailerCapacity)}

        for cargo in filteredCargos {
            var cargoIsLoaded = false
            for (index, vehicle) in filteredVehicles.enumerated() {
                let vehicleIsPermitted = vehicle.cargoIsPermitted(storage: vehicle.permittedCargoTypes,
                                                                  cargo: cargo.type)
                let trailerIsPermitted = vehicle.cargoIsPermitted(
                    storage: (vehicle as? Truck)?.trailerTypes,
                    cargo: cargo.type)
                
                if isCapacityEnough(vehicle: vehicle,
                                    weight: cargo.weight,
                                    vehicleIsPermitted: vehicleIsPermitted,
                                    trailerIsPermitted: trailerIsPermitted) {
                    reserveCapacity(cargoWeight: cargo.weight,
                                   vehicleCapacity: &vehiclesCapacities[index],
                                   vehicleIsPermitted: vehicleIsPermitted,
                                   trailerIsPermitted: trailerIsPermitted)
                    cargoIsLoaded = true
                    break
                }
            }

            if !cargoIsLoaded {
                return false
            }
        }

        return true
    }
}


private extension Fleet {
    // проверяем, что места под груз достаточно
    func isCapacityEnough(vehicle: Vehicle,
                          weight: Int,
                          vehicleIsPermitted: Bool,
                          trailerIsPermitted: Bool) -> Bool {
        let permittedCapacity = 
        (vehicleIsPermitted ? vehicle.capacity : 0) +
        (trailerIsPermitted ? (vehicle as? Truck)?.trailerCapacity ?? 0 : 0)
        
        return weight <= permittedCapacity
    }
    
    // резервируем место под груз
    func reserveCapacity(cargoWeight: Int,
                         vehicleCapacity: inout GeneralVehicalCapacity,
                         vehicleIsPermitted: Bool,
                         trailerIsPermitted: Bool) {
        var currentWeight = cargoWeight
        if vehicleIsPermitted {
            if vehicleCapacity.carCapacity >= currentWeight {
                vehicleCapacity.carCapacity -= currentWeight
            } else {
                vehicleCapacity.trailerCapacity? -= currentWeight - vehicleCapacity.carCapacity
                vehicleCapacity.carCapacity = 0
            }
        } else {
            vehicleCapacity.trailerCapacity? -= currentWeight
        }
    }
}
