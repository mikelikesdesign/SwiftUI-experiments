//
//  ContentView.swift
//  calculator metric
//
//  Created by Michael Lee on 4/14/24.
//

import SwiftUI

struct ContentView: View {
    @State private var inputNumber: String = ""
    @State private var hasInputChanged: Bool = false
    @State private var isReversed: Bool = false

    var conversions: [Conversion] {
        if isReversed {
            return [
                Conversion(label: "°C to °F", value: celsiusToFahrenheit),
                Conversion(label: "Kilograms to Pounds", value: kilogramsToPounds),
                Conversion(label: "Kilometers to Miles", value: kilometersToMiles),
                Conversion(label: "Meters to Feet", value: metersToFeet),
                Conversion(label: "Centimeters to Inches", value: centimetersToInches)
            ]
        } else {
            return [
                Conversion(label: "°F to °C", value: fahrenheitToCelsius),
                Conversion(label: "Pounds to Kilograms", value: poundsToKilograms),
                Conversion(label: "Miles to Kilometers", value: milesToKilometers),
                Conversion(label: "Feet to Meters", value: feetToMeters),
                Conversion(label: "Inches to Centimeters", value: inchesToCentimeters)
            ]
        }
    }

    var fahrenheitToCelsius: Double {
        guard let number = Double(inputNumber) else { return 0 }
        return (number - 32) * 5 / 9
    }

    var celsiusToFahrenheit: Double {
        guard let number = Double(inputNumber) else { return 0 }
        return (number * 9 / 5) + 32
    }

    var poundsToKilograms: Double {
        guard let number = Double(inputNumber) else { return 0 }
        return number * 0.45359237
    }

    var kilogramsToPounds: Double {
        guard let number = Double(inputNumber) else { return 0 }
        return number / 0.45359237
    }

    var milesToKilometers: Double {
        guard let number = Double(inputNumber) else { return 0 }
        return number * 1.60934
    }

    var kilometersToMiles: Double {
        guard let number = Double(inputNumber) else { return 0 }
        return number / 1.60934
    }

    var feetToMeters: Double {
        guard let number = Double(inputNumber) else { return 0 }
        return number * 0.3048
    }

    var metersToFeet: Double {
        guard let number = Double(inputNumber) else { return 0 }
        return number / 0.3048
    }

    var inchesToCentimeters: Double {
        guard let number = Double(inputNumber) else { return 0 }
        return number * 2.54
    }

    var centimetersToInches: Double {
        guard let number = Double(inputNumber) else { return 0 }
        return number / 2.54
    }

    var body: some View {
        VStack {
            TextField("Enter a number", text: $inputNumber, onEditingChanged: { _ in
                self.hasInputChanged.toggle()
            })
                .font(.largeTitle)
                .foregroundColor(.primary)
                .keyboardType(.numberPad)
                .padding()
                .cornerRadius(10)
            
            ScrollView {
                VStack {
                    ForEach(conversions, id: \.label) { conversion in
                        ConversionView(label: conversion.label, output: formattedNumber(number: conversion.value), hasInputChanged: $hasInputChanged)
                            .onLongPressGesture {
                                self.isReversed.toggle() // toggles the conversions on long press
                            }
                    }
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .foregroundColor(Color(red: 0, green: 224/255, blue: 117/255))
        .onTapGesture {
            hideKeyboard()
        }
    }

    func formattedNumber(number: Double) -> String {
        return number.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", number) : String(format: "%.2f", number)
    }
}

struct Conversion: Identifiable {
    var id: String { label }
    let label: String
    let value: Double
}

struct ConversionView: View {
    var label: String
    var output: String
    @Binding var hasInputChanged: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .fontWeight(.regular)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(output)
                .font(.system(size: 40))
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .allowsTightening(true)
                .frame(alignment: .trailing)
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.3), value: output)
        }
        .frame(height: 50)
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

