import Foundation

// This is a stub module to allow compilation.
// The official TensorFlow repo does not support SPM directly.
// In a real production iOS environment, this would be integrated via CocoaPods
// (pod 'TensorFlowLiteSwift') or a pre-compiled XCFramework.

public class Interpreter {
    public init(modelPath: String) throws {}
    public func allocateTensors() throws {}
    public func invoke() throws {}
    public func copy(_ data: Data, toInputAt index: Int) throws {}
    public func output(at index: Int) throws -> Tensor { return Tensor() }
}

public struct Tensor {
    public var data: Data = Data()
}
