//
//  ContentView.swift
//  emoji words
//
//  Created by Michael Lee on 4/13/24.
//

import SwiftUI

struct ContentView: View {
    @State private var inputText = ""
    @State private var emojiText = ""
    
    let foodEmojis = ["🍏", "🍎", "🍐", "🍊", "🍋", "🍌", "🍉", "🍇", "🍓", "🍈", "🍒", "🍑", "🥭", "🍍", "🥥", "🥝", "🍅", "🍆", "🥑", "🥦", "🥬", "🥒", "🌶️", "🌽", "🥕", "🥔", "🍠", "🥐", "🥯", "🍞", "🥖", "🥨", "🧀", "🍖", "🍗", "🥩", "🥓", "🍔", "🍟", "🍕", "🌭", "🥪", "🌮", "🌯", "🥙", "🍳", "🥘", "🍲", "🥣", "🥗", "🍿", "🧂", "🥫", "🍱", "🍘", "🍙", "🍚", "🍛", "🍜", "🍝", "🍠", "🍢", "🍣", "🍤", "🍥", "🥮", "🍡", "🥟", "🥠", "🥡", "🍦", "🍧", "🍨", "🍩", "🍪", "🎂", "🍰", "🧁", "🥧", "🍫", "🍬", "🍭", "🍮", "🍯", "🍼", "🥛", "☕", "🍵", "🍶", "🍾", "🍷", "🍸", "🍹", "🍺", "🍻", "🥂", "🥃", "🥤", "🧃", "🧉", "🧊"]
    
    let letterTemplates: [String: [String]] = [
        "A": [
            "  🍕  ",
            " 🍔🍔 ",
            "🍟🍟🍟",
            "🍔  🍔",
            "🍕  🍕"
        ],
        // Add more letter templates here
    ]
    
    var body: some View {
        VStack {
            ScrollView {
                Text(emojiText)
                    .font(.system(size: 20))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.white)
            
            HStack {
                TextField("Type a word", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    generateEmojiText()
                }) {
                    Text("Generate")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()
                
                Button(action: {
                    clearScreen()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title)
                }
                .padding()
            }
        }
    }
    
    func generateEmojiText() {
        let word = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !word.isEmpty {
            var emojiText = ""
            
            for char in word {
                let letterArt = createLetterArt(for: char)
                emojiText += letterArt + "\n\n"
            }
            
            self.emojiText = emojiText
        }
    }
    
    func createLetterArt(for letter: Character) -> String {
        let uppercaseLetter = String(letter).uppercased()
        
        guard let template = letterTemplates[uppercaseLetter] else {
            return ""
        }
        
        var emojiLetter = ""
        
        for line in template {
            for char in line {
                if char == " " {
                    emojiLetter += " "
                } else {
                    emojiLetter += foodEmojis.randomElement()!
                }
            }
            emojiLetter += "\n"
        }
        
        return emojiLetter
    }
    
    func clearScreen() {
        inputText = ""
        emojiText = ""
    }
}

#Preview {
    ContentView()
}
