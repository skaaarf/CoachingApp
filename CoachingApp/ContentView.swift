import SwiftUI

struct ContentView: View {
    @StateObject private var service = CoachingService()
    @State private var inputText = ""
    
    var body: some View {
        VStack {
            Text("あなたのコーチ")
                .font(.headline)
                .padding()
            
            ScrollView {
                ForEach(service.messages) { message in
                    MessageRow(message: message)
                }
            }
            
            HStack {
                TextField("メッセージを入力", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.leading)
                
                Button("送信") {
                    let text = inputText
                    inputText = ""
                    Task {
                        await service.sendMessage(text)
                    }
                }
                .padding(.trailing)
                .disabled(inputText.isEmpty)
            }
            .padding(.vertical)
        }
    }
}

struct MessageRow: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .assistant {
                VStack(alignment: .leading) {
                    Text("コーチ")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(message.content)
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing) {
                    Text("あなた")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(message.content)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
