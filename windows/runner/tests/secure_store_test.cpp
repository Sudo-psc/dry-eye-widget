#include "secure_store_windows.h"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <optional>
#include <stdexcept>
#include <string>
#include <vector>

namespace fs = std::filesystem;

namespace {

void Check(bool condition, const char* description) {
  if (!condition) throw std::runtime_error(description);
}

class AppDataGuard {
 public:
  AppDataGuard() {
    const DWORD required = GetEnvironmentVariableW(L"APPDATA", nullptr, 0);
    if (required != 0) {
      std::vector<wchar_t> buffer(required);
      const DWORD length =
          GetEnvironmentVariableW(L"APPDATA", buffer.data(), required);
      Check(length > 0 && length < required, "read original APPDATA");
      original_ = std::wstring(buffer.data(), length);
    }
  }

  ~AppDataGuard() {
    SetEnvironmentVariableW(L"APPDATA", original_ ? original_->c_str() : nullptr);
  }

  void Set(const fs::path& path) {
    Check(SetEnvironmentVariableW(L"APPDATA", path.c_str()) != 0, "set APPDATA");
  }

 private:
  std::optional<std::wstring> original_;
};

void CheckValue(const char* key, const std::string& expected) {
  const auto read = secure_store::Read(key);
  Check(read.error == ERROR_SUCCESS && read.value == expected,
        "read must return the last committed value");
}

void RunTests(const fs::path& root) {
  AppDataGuard appdata;
  appdata.Set(root);
  const auto missing = secure_store::Read("absent");
  Check(missing.error == ERROR_SUCCESS && !missing.value, "missing key is null");
  Check(secure_store::Delete("absent") == ERROR_SUCCESS,
        "deleting a missing key is idempotent");
  Check(secure_store::Write("presence_model_enc", "old-value") == ERROR_SUCCESS,
        "write initial DPAPI value");
  CheckValue("presence_model_enc", "old-value");
  Check(secure_store::Write("presence_model_enc", "new-value") == ERROR_SUCCESS,
        "replace initial DPAPI value");
  CheckValue("presence_model_enc", "new-value");
  Check(secure_store::Write("empty", "") == ERROR_SUCCESS, "write empty value");
  CheckValue("empty", "");

  const fs::path blob = root / L"dry_eye_widget" / L"presence_model_enc.bin";
  HANDLE locked = CreateFileW(blob.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                              OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  Check(locked != INVALID_HANDLE_VALUE, "lock old value against replacement");
  const DWORD write_error = secure_store::Write("presence_model_enc", "lost-value");
  const DWORD delete_error = secure_store::Delete("presence_model_enc");
  CloseHandle(locked);
  Check(write_error != ERROR_SUCCESS, "locked replacement must report failure");
  Check(delete_error != ERROR_SUCCESS, "locked delete must report failure");
  CheckValue("presence_model_enc", "new-value");
  for (const auto& entry : fs::directory_iterator(blob.parent_path())) {
    Check(entry.path().filename().wstring().find(L".tmp.") == std::wstring::npos,
          "failed replacement must remove its temporary file");
  }

  {
    std::ofstream corrupt(blob, std::ios::binary | std::ios::trunc);
    corrupt << "not a DPAPI blob";
  }
  Check(secure_store::Read("presence_model_enc").error != ERROR_SUCCESS,
        "corrupt encrypted data must be an error, not a missing key");
  Check(secure_store::Delete("presence_model_enc") == ERROR_SUCCESS,
        "delete corrupted value");

  // A regular file at the directory location simulates inaccessible storage.
  const fs::path blocked = root / L"blocked";
  fs::create_directory(blocked);
  { std::ofstream(blocked / L"dry_eye_widget") << "occupied"; }
  appdata.Set(blocked);
  Check(secure_store::Write("model", "value") != ERROR_SUCCESS,
        "invalid storage directory must report failure");

  fs::path long_root = root;
  for (int i = 0; i < 6; ++i) {
    long_root /= std::wstring(50, L'x') + std::to_wstring(i);
  }
  // Use the extended path only for fixture creation; pass the ordinary long
  // APPDATA to production code to exercise its sizing and path conversion.
  fs::create_directories(fs::path(L"\\\\?\\" + long_root.wstring()));
  Check(long_root.wstring().size() > MAX_PATH, "fixture exceeds MAX_PATH");
  appdata.Set(long_root);
  Check(secure_store::Write("long_profile", "long-path-value") == ERROR_SUCCESS,
        "write with APPDATA longer than MAX_PATH");
  CheckValue("long_profile", "long-path-value");
  Check(secure_store::Delete("long_profile") == ERROR_SUCCESS,
        "delete with APPDATA longer than MAX_PATH");

  appdata.Set(fs::path(L"relative-profile"));
  Check(secure_store::Write("model", "value") == ERROR_BAD_PATHNAME,
        "relative APPDATA must not write relative to the working directory");
  Check(SetEnvironmentVariableW(L"APPDATA", nullptr) != 0, "remove APPDATA");
  Check(secure_store::Read("model").error == ERROR_ENVVAR_NOT_FOUND,
        "missing APPDATA must not be treated as a missing key");
  Check(secure_store::Write("model", "value") == ERROR_ENVVAR_NOT_FOUND,
        "missing APPDATA must not write to the drive root");
}

}  // namespace

int main() {
  const fs::path root = fs::temp_directory_path() /
                       (L"dry-eye-secure-store-test-" +
                        std::to_wstring(GetCurrentProcessId()) + L"-" +
                        std::to_wstring(GetTickCount64()));
  int result = 0;
  try {
    fs::create_directories(root);
    RunTests(root);
    std::cout << "PASS: DPAPI round-trip, atomic failure, delete, corrupt blob, "
                 "missing and long APPDATA\n";
  } catch (const std::exception& error) {
    std::cerr << "FAIL: " << error.what() << '\n';
    result = 1;
  }
  std::error_code cleanup_error;
  fs::remove_all(fs::path(L"\\\\?\\" + root.wstring()), cleanup_error);
  if (cleanup_error) {
    std::cerr << "FAIL: temporary test data cleanup\n";
    result = 1;
  }
  return result;
}
