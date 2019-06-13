import Combine
import Foundation

// MARK: FileHandleWritePublisher
struct FileHandleWritePublisher {
    let fileHandle: FileHandle

    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }
}

extension FileHandleWritePublisher : Publisher {
    public typealias Output = FileHandle
    typealias Failure = Error

    func receive<S>(subscriber: S) where S : Subscriber, FileHandleWritePublisher.Failure == S.Failure, FileHandleWritePublisher.Output == S.Input {

        DispatchQueue.main.async {
            self.fileHandle.writeabilityHandler = { (handle) in
                _ = subscriber.receive(handle)
            }
        }
    }
}

extension FileHandleWritePublisher : Cancellable {
    func cancel() {
        DispatchQueue.main.async {
            self.fileHandle.writeabilityHandler = nil
        }
    }
}

// MARK: FileHandleReadPublisher
struct FileHandleReadPublisher {
    let fileHandle: FileHandle

    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }
}

extension FileHandleReadPublisher : Publisher {
    public typealias Output = Data
    typealias Failure = Error

    func receive<S>(subscriber: S) where S : Subscriber, FileHandleReadPublisher.Failure == S.Failure, FileHandleReadPublisher.Output == S.Input {

        DispatchQueue.main.async {
            self.fileHandle.readabilityHandler = { (handle) in
                self.readData(handle, for: subscriber)
            }
        }
    }

    private func readData<S>(_ handle: FileHandle, for subscriber: S) where S : Subscriber, FileHandleReadPublisher.Failure == S.Failure, FileHandleReadPublisher.Output == S.Input {
        do {
            let data = try handle.__readDataUp(toLength: Int.max)

            _ = subscriber.receive(data)
        } catch {
            subscriber.receive(completion: .failure(error))

            cancel()
        }
    }
}

extension FileHandleReadPublisher : Cancellable {
    func cancel() {
        DispatchQueue.main.async {
            self.fileHandle.readabilityHandler = nil
        }
    }
}

// MARK: FileHandle Extensions
extension FileHandle {
    var readPublisher: AnyPublisher<Data, Error> {
        return FileHandleReadPublisher(fileHandle: self).eraseToAnyPublisher()
    }

    var writePublisher: AnyPublisher<FileHandle, Error> {
        return FileHandleWritePublisher(fileHandle: self).eraseToAnyPublisher()
    }
}

// MARK: Goal

// turn a struct into a protocol message, which is a wrapped JSON-RPC message
//
// - Message(uri: "someuri")
// - {"jsonrpc":"2.0","id":1,"result":{"uri":"someuri"}}
// - Content-Length: 51\r\n\r\n{"jsonrpc":"2.0","id":1,"result":{"uri":"someuri"}}
// - write that to an outgoing buffer
// - flush that buffer to a FileHandle as it is writable

struct Message {
    let uri: String
}
