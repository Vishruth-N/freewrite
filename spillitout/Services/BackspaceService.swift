import Foundation

class BackspaceService: ObservableObject {
    @Published var isBackspaceDisabled = false
    
    func toggleBackspaceDisabled() {
        isBackspaceDisabled.toggle()
        UserDefaults.standard.set(isBackspaceDisabled, forKey: "backspaceDisabled")
    }
    
    init() {
        self.isBackspaceDisabled = UserDefaults.standard.bool(forKey: "backspaceDisabled")
    }
}