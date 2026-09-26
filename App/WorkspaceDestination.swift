import Foundation

enum WorkspaceDestination: String, CaseIterable, Identifiable {
  case overview
  case passports
  case documents

  var id: String {
    rawValue
  }

  var title: String {
    switch self {
    case .overview:
      "Overview"
    case .passports:
      "Passports"
    case .documents:
      "Travel Documents"
    }
  }

  var symbol: String {
    switch self {
    case .overview:
      "square.grid.2x2.fill"
    case .passports:
      "person.text.rectangle.fill"
    case .documents:
      "text.document.fill"
    }
  }

  var emptyTitle: String {
    switch self {
    case .overview:
      "Your travel workspace"
    case .passports:
      "No passports yet"
    case .documents:
      "No travel documents yet"
    }
  }

  var emptyMessage: String {
    switch self {
    case .overview:
      "Your passport and essential travel documents will have a home here."
    case .passports:
      "Passports you add will appear here."
    case .documents:
      "Your saved travel documents will appear here."
    }
  }
}
