//
//  ContentView.swift
//  Pool Chemistry Tracker
//
//  Created by Patrick on 7/25/24.
//


// Make it so that the button is not clickable until all the input is valid

import SwiftUI
import SwiftData

enum PoolConditions: String, CaseIterable {
    case Clear
    case Cloudy
    case Green
}

enum PoolType: String, CaseIterable {
    case SaltCl
    case Floater
    case Feeder
    case None
}

enum Rounding: String, CaseIterable{
    case Yes
    case No
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var showingSheet = false
    @Query private var items: [Item]
    

    

    
    var caReadings: [Int] = [0, 100, 250, 500, 1000]
    @State private var caReading = 250
    
    var totalCl: [Float] = [0.0, 0.5, 1.0, 3.0, 5.0, 10.0]
    @State private var totalClReading: Float = 1.0
    
    var freeCl: [Float] = [0.0, 0.5, 1.0, 3.0, 5.0, 10.0, 20.0]
    @State private var freeClReading: Float = 1.0
    
    var pH: [Float] = [6.2, 6.8, 7.2, 7.8, 8.4]
    @State private var pHReading: Float = 7.2
    
    var alkalinity: [Int] = [0, 40, 80, 120, 180, 240]
    @State private var alkalinityReading = 80
    
    var cya: [Int] = [0, 30, 40, 50, 100, 150, 300]
    @State private var cyaReading = 50
    
    @State private var poolType: PoolType = .SaltCl
    @State private var sizeInput: String = ""
    @State private var poolCondition: PoolConditions = .Clear
    @State private var salinityInput: String = ""
    @State private var roundBool: Rounding = .No
    
    
    private func isValidSize(_ input: String) -> Bool {
        let size = Int(input) ?? 0
        if (size <= 0){
            return false
        }else{
            return true
        }
    }
    
    var body: some View {
        Text("Enter the estimated pool size in gallons")
        
        TextField("Size:", text: $sizeInput)
            .padding()
            .keyboardType(.numberPad)
        //Text(sizeInput)

        
        let size = Int(sizeInput) ?? 0
        

    
        
        VStack{
            
            //Chemical Readings
            List{
                Picker("Round to half a pound (ounce for liquids)?", selection: $roundBool) {
                    ForEach(Rounding.allCases, id: \.self) {
                        roundBool in Text(roundBool.rawValue)
                    }
                }
                Picker("Pool type", selection: $poolType) {
                    ForEach(PoolType.allCases, id: \.self) { poolType in
                        Text(poolType.rawValue)
                    }
                }
                Picker("Pool condition", selection: $poolCondition) {
                    ForEach(PoolConditions.allCases, id: \.self) { poolCondition in
                        Text(poolCondition.rawValue)
                    }
                }
                Picker("Ca", selection: $caReading) {
                    ForEach(caReadings, id: \.self) { number in
                        Text("\(number)")
                    }
                }
                Picker("Total Cl", selection: $totalClReading) {
                    ForEach(totalCl, id: \.self) { number in
                        Text("\(number, specifier: "%.1f")")
                    }
                }
                Picker("Free Cl", selection: $freeClReading) {
                    ForEach(freeCl, id: \.self) { number in
                        Text("\(number, specifier: "%.1f")")
                    }
                }
                Picker("pH", selection: $pHReading) {
                    ForEach(pH, id: \.self) { number in
                        Text("\(number, specifier: "%.1f")")
                    }
                }

                Picker("Alkalinity", selection: $alkalinityReading) {
                    ForEach(alkalinity, id: \.self) { number in
                        Text("\(number)")
                    }
                }
                Picker("CYA", selection: $cyaReading) {
                    ForEach(cya, id: \.self) { number in
                        Text("\(number)")
                    }
                }
                if(poolType == .SaltCl){
                    Text("Enter the salinity reading as ppm number (not the decimal)")
                    
                    TextField("Size:", text: $salinityInput)
                        .padding()
                        .keyboardType(.numberPad)
                    Text(salinityInput)
                }
            }
        
            let salinity = Int(salinityInput) ?? 0
            
            if(isValidSize(sizeInput)){
                Button("Calculate") {
                    showingSheet.toggle()
                }
                
                           .sheet(isPresented: $showingSheet) {
                               // contents of the sheet
                               if(poolType == .SaltCl){
                                   SaltView(size: size, poolCondition: poolCondition, ca: caReading, totalCl: totalClReading, freeCl: freeClReading, pH: pHReading, alkalinity: alkalinityReading, cya: cyaReading, salinity: salinity, roundBool: roundBool)
                               }else{
                                   ChlorineView(size: size, poolCondition: poolCondition, ca: caReading, totalCl: totalClReading, freeCl: freeClReading, pH: pHReading, alkalinity: alkalinityReading, cya: cyaReading, roundBool: roundBool, poolType: poolType)
                               }
                           }
            }else{
                Text("Calculate").foregroundColor(.gray)
            }
 
        }
        

    }
    
    
    
    
}


struct SaltView: View {

    let size: Int
    let poolCondition: PoolConditions
    let ca: Int
    let totalCl: Float
    let freeCl: Float
    let pH: Float
    let alkalinity: Int
    let cya: Int
    let salinity: Int
    let roundBool: Rounding
    @State private var pounds: Float = 0.0
    var salinityApproximations: [Int] = [0, 400, 800, 1200, 1600, 2000, 2400, 2800, 3200, 3600]
    
    var body: some View {
        //Alkalinity
        if(alkalinity < 80){
            Text("Add \(calculateAlkalinityChange(), specifier: "%.1f") pounds of Alkalinity Plus.")
        }else if(alkalinity > 120){
            Text("Add \(calculateAlkalinityChange(), specifier: "%.1f") pounds of pH Minus.")
        }
        //pH
        if(pH < 7.2){
            Text("Add \(calculatepHChange(), specifier: "%.1f") of pH Plus.")
        }else if(pH > 7.8){
            if(alkalinity > 120){
                if(calculatepHChange() <= calculateAlkalinityChange()){
                    Text("No more pH Minus needed - addition for alkalinity was sufficient.")
                }else{
                    Text("Add \((calculatepHChange() - calculateAlkalinityChange()), specifier: "%.1f") pounds of pH Minus.")
                }
            }else{
                Text("Add \(calculatepHChange(), specifier: "%.1f") pounds of pH Minus.")
            }
        }
        //salinity
        if(salinity < 3000){
            Text("Refer to Salt Bag guide in handbook.")
        }
        
        //Chlorine
        if(freeCl == 0.0 || ((totalCl - freeCl) > 1.0)){
            if(poolCondition != .Clear){
                Text("Add 3 or 4 bags of 1 lb Shock.")
            }else{
                Text("Add 1 or 2 bags of 1 lb Shock.")
            }
        }else if(freeCl > 3.0){
            //ChlorOut
            Text("Add \(calculateChlorOut(), specifier: "%.1f") pounds of Chlor Out.")
            if(freeCl > 5.0){
                Text("Turn down Chlorine generation to 10 or 20%.")
            }
            
        }
        //Ca
        if(ca < 250){
            Text("Add \(calculateCalciumChange(), specifier: "%.2f") pounds of Ca Increaser.")
        }
        //CYA
        if(cya < 50){
            if(cya == 0){
                Text("Add \(calculateCYAChange(), specifier: "%.1f") pounds of Conditioner.")
            }else{
                Text("You can add \(calculateCYAChange(), specifier: "%.1f") pounds of Conditioner.")
            }
        }
        //Green or Cloudy
        if(poolCondition == .Green){
            Text("Add between \(calculateAlgaecide().0, specifier: "%.1f") and \(calculateAlgaecide().1, specifier: "%.1f") ounces of Algaecide 60.")
            Text("Add between \(calculateClarifier().0, specifier: "%.1f") and \(calculateClarifier().1, specifier: "%.1f") ounces of Clarifier.")
        }else if(poolCondition == .Cloudy){
            Text("Add between \(calculateClarifier().0, specifier: "%.1f") and \(calculateClarifier().1, specifier: "%.1f") ounces of Clarifier.")
        }
        
    }
    
    //Method for rounding to nearest half pound
    private func round(unrounded: Float) -> Float{
        if (unrounded - unrounded.rounded(.down) < 0.25){
            return unrounded.rounded(.down)
        }else if (unrounded - unrounded.rounded(.down) >= 0.75){
            return unrounded.rounded(.up)
        }else{
            return unrounded.rounded(.down) + 0.5
        }
    }
    
    // Method to calculate pounds of Alkalinity Plus needed
    private func calculateAlkalinityChange() -> Float {
        var pounds = 1.5 * Float(size) / 10000.0 * Float(abs(Float(100 - alkalinity) / 10))
        if(roundBool == .Yes){
            return round(unrounded: pounds)
        }
        return pounds
    }
    
    //Method to calculate amount of pH Plus or Minus needed
    private func calculatepHChange() -> Float {
        if(pH < 7.2){
            var pounds = 1.0 * Float(size) / 10000.0
            if(roundBool == .Yes){
                return round(unrounded: pounds)
            }
            return pounds
        }else if(pH == 7.8){
            var oz = 20 * Float(size) / 10000.0
            if(roundBool == .Yes){
                return round(unrounded: pounds)
            }
            return Float(oz / 16)
        }else{
            var oz = 30 * Float(size) / 10000.0
            if(roundBool == .Yes){
                return round(unrounded: pounds)
            }
            return Float(oz / 16)
        }
    }
    
    //Method to calculate amount of ChlorOut needed
    private func calculateChlorOut() -> Float {
        var oz = 2.5 * Float(size) / 10000.0 * (freeCl - 2.0)
        var pounds = oz / 16
        if(roundBool == .Yes){
            return round(unrounded: pounds)
        }
        return pounds
    }
    
    //Method to calculate amount of Calcium Increaser needed
    private func calculateCalciumChange() -> Float {
        var pounds = 1.25 * Float(size) / 10000.0 * Float(abs(300.0 - Float(ca) / 10.0))
        if(roundBool == .Yes){
            return round(unrounded: pounds)
        }
        return pounds
    }
   
    //Method to calculate amount of Conditioner needed
    private func calculateCYAChange() -> Float {
        var pounds = 2.5 * Float(size) / 10000.0 / 3.0 * Float((50 - cya) / 10)
        if(roundBool == .Yes){
            return round(unrounded: pounds)
        }
        return pounds
    }
    
    //Method to calculate amount of Algaecide 60 needed
    private func calculateAlgaecide() -> (Float, Float){
        var lower = Float(12.0 * Float(size / 10000))
        var higher = Float(18.0 * Float(size / 10000))
        if(roundBool == .Yes){
            lower.round()
            higher.round()
        }
        var tuple = (first: lower, last: higher)
        return tuple
    }
    
    //Method to calculate amount of Clarifier needed
    private func calculateClarifier() -> (Float, Float){
        var lower = 0.2 * Float(size / 1000)
        var higher = 0.4 * Float(size / 1000)
        if(roundBool == .Yes){
            lower.round()
            higher.round()
        }
        var tuple = (first: lower, last: higher)
        return tuple
    }
}

struct ChlorineView: View {
    
    let size: Int
    let poolCondition: PoolConditions
    let ca: Int
    let totalCl: Float
    let freeCl: Float
    let pH: Float
    let alkalinity: Int
    let cya: Int
    let roundBool: Rounding
    let poolType: PoolType
    
    @State private var pounds: Float = 0.0
    
    var body: some View {
        //Alkalinity
        if(alkalinity < 80){
            Text("Add \(calculateAlkalinityChange(), specifier: "%.1f") pounds of Alkalinity Plus.")
        }else if(alkalinity > 120){
            Text("Add \(calculateAlkalinityChange(), specifier: "%.1f") pounds of pH Minus.")
        }
        //pH
        if(pH < 7.2){
            Text("Add \(calculatepHChange(), specifier: "%.1f") pounds of pH Plus.")
        }else if(pH > 7.8){
            if(calculatepHChange() <= calculateAlkalinityChange()){
                Text("No more pH Minus needed - addition for alkalinity was sufficient.")
            }else{
                Text("Add \((calculatepHChange() - calculateAlkalinityChange()), specifier: "%.1f") pounds of pH Minus.")
            }
        }
        //Chlorine
        if(freeCl == 0.0 || ((totalCl - freeCl) > 1.0)){
            if(poolCondition != .Clear){
                Text("Add 3 or 4 bags of 1 lb Shock.")
            }else{
                Text("Add 1 or 2 bags of 1 lb Shock.")
            }
            if(poolType == .Feeder){
                Text("There should be \(calculateTabs(), specifier: "%.0f") tab(s) in the Feeder.")
            }else if(poolType == .Floater){
                Text("There should be \(calculateTabs(), specifier: "%.0f") tab(s) in the Floater.")
            }else{
                Text("Place \(calculateTabs()) in the skimmer and make a note that there is no system in place.")
            }
        }else if(freeCl > 3.0){
            //ChlorOut
            Text("Add \(calculateChlorOut(), specifier: "%.1f") of Chlor Out.")
            if(freeCl > 5.0){
                Text("Turn down Chlorine generation to 10 or 20%.")
            }
            
        }
        //Ca
        if(ca < 250){
            Text("Add \(calculateCalciumChange(), specifier: "%.2f") pounds of Ca Increaser.")
        }
        //CYA
        if(cya < 50){
            if(cya == 0){
                Text("Add \(calculateCYAChange(), specifier: "%.1f") pounds of Conditioner.")
            }else{
                Text("You can add \(calculateCYAChange(), specifier: "%.1f") pounds of Conditioner.")
            }
        }
        //Green or Cloudy
        if(poolCondition == .Green){
            Text("Add between \(calculateAlgaecide().0, specifier: "%.1f") and \(calculateAlgaecide().1, specifier: "%.1f") ounces of Algaecide 60.")
            Text("Add between \(calculateClarifier().0, specifier: "%.1f") and \(calculateClarifier().1, specifier: "%.1f") ounces of Clarifier.")
        }else if(poolCondition == .Cloudy){
            Text("Add between \(calculateClarifier().0, specifier: "%.1f") and \(calculateClarifier().1, specifier: "%.1f") ounces of Clarifier.")
        }
        
    }
    
    //Method for rounding to nearest half pound
    private func round(unrounded: Float) -> Float{
        if (unrounded - unrounded.rounded(.down) < 0.25){
            return unrounded.rounded(.down)
        }else if (unrounded - unrounded.rounded(.down) >= 0.75){
            return unrounded.rounded(.up)
        }else{
            return unrounded.rounded(.down) + 0.5
        }
    }
    
    // Method to calculate pounds of Alkalinity Plus needed
    private func calculateAlkalinityChange() -> Float {
        var pounds = 1.5 * Float(size) / 10000.0 * Float(abs(Float(100 - alkalinity) / Float(10)))
        if(roundBool == .Yes){
            return round(unrounded: pounds)
        }
        return pounds
    }
    
    private func calculatepHChange() -> Float {
        if(pH < 7.2){
            var pounds = 1.0 * Float(size) / 10000.0
            if(roundBool == .Yes){
                return round(unrounded: pounds)
            }
            return pounds
        }else if(pH == 7.8){
            var oz = 20 * Float(size) / 10000.0
            if(roundBool == .Yes){
                return round(unrounded: pounds)
            }
            return Float(oz / 16)
        }else{
            var oz = 30 * Float(size) / 10000.0
            if(roundBool == .Yes){
                return round(unrounded: pounds)
            }
            return Float(oz / 16)
        }
    }
    
    private func calculateTabs() -> Float{
        var tabs = Float(size / 5000)
        tabs.round()
        return tabs
    }
    
    private func calculateChlorOut() -> Float {
        var oz = 2.5 * Float(size) / 10000.0 * (freeCl - 2.0)
        var pounds = oz / 16
        if(roundBool == .Yes){
            return round(unrounded: pounds)
        }
        return pounds
    }
    
    private func calculateCalciumChange() -> Float {
        var pounds = 1.25 * Float(size) / 10000.0 * Float(abs(Float(300 - ca) / 10))
        if(roundBool == .Yes){
            return round(unrounded: pounds)
        }
        return pounds
    }
    
    private func calculateCYAChange() -> Float {
        var pounds = 2.5 * Float(size) / 10000.0 / 3 * Float((50 - cya) / 10)
        if(roundBool == .Yes){
            return round(unrounded: pounds)
        }
        return pounds
    }
    
    private func calculateAlgaecide() -> (Float, Float){
        var lower = Float(12.0 * Float(size) / 10000.0)
        var higher = Float(18.0 * Float(size) / 10000.0)
        if(roundBool == .Yes){
            lower.round()
            higher.round()
        }
        var tuple = (first: lower, last: higher)
        return tuple
    }
    
    private func calculateClarifier() -> (Float, Float){
        var lower = 0.2 * Float(size / 1000)
        var higher = 0.4 * Float(size / 1000)
        if(roundBool == .Yes){
            lower.round()
            higher.round()
        }
        var tuple = (first: lower, last: higher)
        return tuple
    }
}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
