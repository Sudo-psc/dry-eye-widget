#ifndef RUNNER_SECURE_STORE_WINDOWS_H_
#define RUNNER_SECURE_STORE_WINDOWS_H_

#include <windows.h>

#include <optional>
#include <string>

namespace secure_store {

// A missing key is a successful read with no value. All other failures retain
// the Win32 error code so callers can distinguish unavailable storage from it.
struct ReadResult {
  DWORD error = ERROR_SUCCESS;
  std::optional<std::string> value;
};

ReadResult Read(const std::string& key);
DWORD Write(const std::string& key, const std::string& value);
DWORD Delete(const std::string& key);

}  // namespace secure_store

#endif  // RUNNER_SECURE_STORE_WINDOWS_H_
