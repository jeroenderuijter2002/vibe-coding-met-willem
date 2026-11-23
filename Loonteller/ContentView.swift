import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "eurosign.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Loonteller")
                .font(.largeTitle.bold())
            Text("Stap 0 werkt!")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
