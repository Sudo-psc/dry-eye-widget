#ifndef RUNNER_WINDOWS_STORE_INTEGRATION_H_
#define RUNNER_WINDOWS_STORE_INTEGRATION_H_

#include <flutter/binary_messenger.h>
#include <windows.h>

#include <memory>

// Package-aware Windows APIs. Own this before the Flutter engine is destroyed;
// HandleMessage must be called by the runner's platform-thread message handler.
class WindowsStoreIntegration {
 public:
  WindowsStoreIntegration(flutter::BinaryMessenger* messenger, HWND window);
  ~WindowsStoreIntegration();

  bool HandleMessage(UINT message);

 private:
  class Impl;
  std::unique_ptr<Impl> impl_;
};

#endif  // RUNNER_WINDOWS_STORE_INTEGRATION_H_
