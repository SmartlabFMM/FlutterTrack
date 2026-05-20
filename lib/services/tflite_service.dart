// Conditional export : FFI (native) ou stub (web)
export 'tflite_service_stub.dart'
    if (dart.library.ffi) 'tflite_service_native.dart';
