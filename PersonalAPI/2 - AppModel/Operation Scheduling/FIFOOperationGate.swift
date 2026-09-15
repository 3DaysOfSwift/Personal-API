import Foundation

/// Serializes complete asynchronous operations, including their suspension points.
/// FIFO means arrival at acquire(), not the order in which callers create Tasks.
/// A cancelled waiter still takes its turn; callers check cancellation before work.
@MainActor final class FIFOOperationGate {
  private var occupied = false
  private var waiters: [CheckedContinuation<Void, Never>] = []

  func acquire() async {
    if !occupied {
      occupied = true
      return
    }
    await withCheckedContinuation { waiters.append($0) }
  }

  func release() {
    if waiters.isEmpty {
      occupied = false
    } else {
      waiters.removeFirst().resume()
    }
  }
}
