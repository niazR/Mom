extension CursorBasedPagination {
  public struct Reverse: PaginationInfo, Hashable {
    public let hasPrevious: Bool
    public let startCursor: String?

    public var canLoadNext: Bool { false }
    public var canLoadPrevious: Bool { hasPrevious }

    public init(hasPrevious: Bool, startCursor: String?) {
      self.hasPrevious = hasPrevious
      self.startCursor = startCursor
    }
  }
}
