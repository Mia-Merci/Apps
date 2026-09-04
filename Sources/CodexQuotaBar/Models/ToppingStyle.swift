enum ToppingStyle: String, CaseIterable, Identifiable {
    case sprinkles
    case chocolate
    case cream

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sprinkles:
            return "Sprinkles"
        case .chocolate:
            return "Chocolate"
        case .cream:
            return "Cream"
        }
    }
}
