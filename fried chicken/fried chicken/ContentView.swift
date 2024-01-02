import SwiftUI

struct ContentView: View {
    @State private var animatedViews: [CGPoint] = []  // Change CGSize to CGPoint
    private let distanceThreshold: CGFloat = 50  // Set a distance threshold
    
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Fried Chicken Club")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.top, 120)
                
                Image("fried_chicken")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 300)
                    .padding(.top)
                
                Spacer()
            }
            
            ForEach(animatedViews.indices, id: \.self) { index in
                AnimatedView()
                    .position(animatedViews[index])
            }
            
            VStack {
                Spacer()
                
                Button(action: {
                    // Action for button
                }) {
                    Text("Get Started")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .background(Color(#colorLiteral(red: 0.1254901961, green: 0.1254901961, blue: 0.1254901961, alpha: 1)))
                        .cornerRadius(100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 100)
                                .stroke(Color(#colorLiteral(red: 0.2117647059, green: 0.2117647059, blue: 0.2117647059, alpha: 1)), lineWidth: 1)
                        )
                        .padding([.leading, .trailing])
                }
                .padding(.bottom, 64)
            }
        }
        .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if let lastPoint = self.animatedViews.last {
                                let distance = sqrt(pow(value.location.x - lastPoint.x, 2) + pow(value.location.y - lastPoint.y, 2))
                                if distance > self.distanceThreshold {
                                    self.animatedViews.append(value.location)  // Now correctly using CGPoint
                                }
                            } else {
                                self.animatedViews.append(value.location)  // Append the first point unconditionally
                            }
                        }
                )
            }
        }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
