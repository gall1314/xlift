import UIKit
import Flutter

// MARK: - TFLite Symbol Preservation
// Force-reference TFLite C symbols so iOS Release builds don't strip them.
// Without this, Dart's FFI lookup fails with "symbol not found" in IPA builds
// (TestFlight/App Store) when calling into flutter_litert / pose_detection.
//
// The mechanism: @_silgen_name declares external C functions whose names
// match the TFLite C API. Touching them below makes the linker mark the
// symbols as "in use", which prevents the strip phase from removing them.
// At runtime, Dart's dlsym() can then find them in the global symbol table.

@_silgen_name("TfLiteInterpreterOptionsCreate")
private func _ff_TfLiteInterpreterOptionsCreate() -> OpaquePointer?

@_silgen_name("TfLiteInterpreterOptionsDelete")
private func _ff_TfLiteInterpreterOptionsDelete(_ options: OpaquePointer?)

@_silgen_name("TfLiteInterpreterOptionsSetNumThreads")
private func _ff_TfLiteInterpreterOptionsSetNumThreads(_ options: OpaquePointer?, _ numThreads: Int32)

@_silgen_name("TfLiteInterpreterOptionsAddDelegate")
private func _ff_TfLiteInterpreterOptionsAddDelegate(_ options: OpaquePointer?, _ delegate: OpaquePointer?)

@_silgen_name("TfLiteInterpreterCreate")
private func _ff_TfLiteInterpreterCreate(_ model: OpaquePointer?, _ options: OpaquePointer?) -> OpaquePointer?

@_silgen_name("TfLiteInterpreterDelete")
private func _ff_TfLiteInterpreterDelete(_ interpreter: OpaquePointer?)

@_silgen_name("TfLiteInterpreterAllocateTensors")
private func _ff_TfLiteInterpreterAllocateTensors(_ interpreter: OpaquePointer?) -> Int32

@_silgen_name("TfLiteInterpreterInvoke")
private func _ff_TfLiteInterpreterInvoke(_ interpreter: OpaquePointer?) -> Int32

@_silgen_name("TfLiteInterpreterGetInputTensorCount")
private func _ff_TfLiteInterpreterGetInputTensorCount(_ interpreter: OpaquePointer?) -> Int32

@_silgen_name("TfLiteInterpreterGetInputTensor")
private func _ff_TfLiteInterpreterGetInputTensor(_ interpreter: OpaquePointer?, _ index: Int32) -> OpaquePointer?

@_silgen_name("TfLiteInterpreterGetOutputTensorCount")
private func _ff_TfLiteInterpreterGetOutputTensorCount(_ interpreter: OpaquePointer?) -> Int32

@_silgen_name("TfLiteInterpreterGetOutputTensor")
private func _ff_TfLiteInterpreterGetOutputTensor(_ interpreter: OpaquePointer?, _ index: Int32) -> OpaquePointer?

@_silgen_name("TfLiteModelCreate")
private func _ff_TfLiteModelCreate(_ data: UnsafeRawPointer?, _ size: Int) -> OpaquePointer?

@_silgen_name("TfLiteModelCreateFromFile")
private func _ff_TfLiteModelCreateFromFile(_ path: UnsafePointer<CChar>?) -> OpaquePointer?

@_silgen_name("TfLiteModelDelete")
private func _ff_TfLiteModelDelete(_ model: OpaquePointer?)

@_silgen_name("TfLiteTensorByteSize")
private func _ff_TfLiteTensorByteSize(_ tensor: OpaquePointer?) -> Int

@_silgen_name("TfLiteTensorCopyFromBuffer")
private func _ff_TfLiteTensorCopyFromBuffer(_ tensor: OpaquePointer?, _ data: UnsafeRawPointer?, _ size: Int) -> Int32

@_silgen_name("TfLiteTensorCopyToBuffer")
private func _ff_TfLiteTensorCopyToBuffer(_ tensor: OpaquePointer?, _ data: UnsafeMutableRawPointer?, _ size: Int) -> Int32

@_silgen_name("TfLiteTensorType")
private func _ff_TfLiteTensorType(_ tensor: OpaquePointer?) -> Int32

@_silgen_name("TfLiteTensorNumDims")
private func _ff_TfLiteTensorNumDims(_ tensor: OpaquePointer?) -> Int32

@_silgen_name("TfLiteTensorDim")
private func _ff_TfLiteTensorDim(_ tensor: OpaquePointer?, _ index: Int32) -> Int32

// Store function references in a global array so the compiler can't optimize
// them away. By placing them at file scope, they're guaranteed to be referenced
// during app initialization.
private let _ffTfLiteSymbolReferences: [Any] = [
    _ff_TfLiteInterpreterOptionsCreate as Any,
    _ff_TfLiteInterpreterOptionsDelete as Any,
    _ff_TfLiteInterpreterOptionsSetNumThreads as Any,
    _ff_TfLiteInterpreterOptionsAddDelegate as Any,
    _ff_TfLiteInterpreterCreate as Any,
    _ff_TfLiteInterpreterDelete as Any,
    _ff_TfLiteInterpreterAllocateTensors as Any,
    _ff_TfLiteInterpreterInvoke as Any,
    _ff_TfLiteInterpreterGetInputTensorCount as Any,
    _ff_TfLiteInterpreterGetInputTensor as Any,
    _ff_TfLiteInterpreterGetOutputTensorCount as Any,
    _ff_TfLiteInterpreterGetOutputTensor as Any,
    _ff_TfLiteModelCreate as Any,
    _ff_TfLiteModelCreateFromFile as Any,
    _ff_TfLiteModelDelete as Any,
    _ff_TfLiteTensorByteSize as Any,
    _ff_TfLiteTensorCopyFromBuffer as Any,
    _ff_TfLiteTensorCopyToBuffer as Any,
    _ff_TfLiteTensorType as Any,
    _ff_TfLiteTensorNumDims as Any,
    _ff_TfLiteTensorDim as Any,
]

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Touch the symbol references so they're guaranteed to be loaded.
    // This prevents the iOS Release strip phase from removing them.
    print("TFLite symbol references count: \(_ffTfLiteSymbolReferences.count)")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}