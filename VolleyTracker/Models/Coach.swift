import Foundation

struct Coach: Identifiable, Equatable {
    let id = UUID()
    let fullName: String
    let age: Int
    let teamName: String
    let email: String
    let password: String
}
