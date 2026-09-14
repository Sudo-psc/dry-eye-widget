#include "secure_store_windows.h"

#include <dpapi.h>

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <filesystem>
#include <utility>
#include <vector>

namespace secure_store {
namespace {

// The stored presence model contains aggregate counts, not an unbounded file.
constexpr DWORD kMaxValueBytes = 16 * 1024 * 1024;
constexpr DWORD kMaxEncryptedBytes = kMaxValueBytes + 64 * 1024;

bool IsMissing(DWORD error) {
  return error == ERROR_FILE_NOT_FOUND || error == ERROR_PATH_NOT_FOUND;
}

DWORD FilePath(const std::string& key, std::wstring* path,
               std::wstring* directory) {
  if (key.empty() || key == "." || key == ".." ||
      !std::all_of(key.begin(), key.end(), [](unsigned char c) {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
               (c >= '0' && c <= '9') || c == '_' || c == '-' || c == '.';
      })) {
    return ERROR_INVALID_NAME;
  }

  // GetEnvironmentVariableW returns the *required* size when its buffer is too
  // small. Re-query if the environment changes between these two calls.
  std::wstring appdata;
  for (int attempt = 0; attempt < 3; ++attempt) {
    const DWORD required = GetEnvironmentVariableW(L"APPDATA", nullptr, 0);
    if (required == 0) return ERROR_ENVVAR_NOT_FOUND;
    std::vector<wchar_t> buffer(required);
    const DWORD length = GetEnvironmentVariableW(L"APPDATA", buffer.data(),
                                                 required);
    if (length == 0) return ERROR_ENVVAR_NOT_FOUND;
    if (length >= required) continue;
    appdata.assign(buffer.data(), length);
    break;
  }
  if (appdata.empty()) return ERROR_RETRY;

  // Keep the existing location and filename, including for redirected profiles.
  // Extended paths support APPDATA paths longer than MAX_PATH without relying
  // on the user's system-wide long-path policy.
  std::replace(appdata.begin(), appdata.end(), L'/', L'\\');
  const std::filesystem::path root(appdata);
  if (!root.is_absolute()) return ERROR_BAD_PATHNAME;
  appdata = root.lexically_normal().wstring();
  // Preserve ordinary paths for existing installations. Include enough room
  // for the key, file extension and unique temporary suffix when deciding
  // whether the extended-path prefix is needed.
  if (appdata.size() + key.size() + 96 >= MAX_PATH &&
      appdata.rfind(L"\\\\?\\", 0) != 0) {
    appdata = appdata.rfind(L"\\\\", 0) == 0
                  ? L"\\\\?\\UNC\\" + appdata.substr(2)
                  : L"\\\\?\\" + appdata;
  }
  if (appdata.back() != L'\\') appdata += L'\\';
  *directory = appdata + L"dry_eye_widget";
  *path = *directory + L"\\" + std::wstring(key.begin(), key.end()) + L".bin";
  return ERROR_SUCCESS;
}

DWORD WriteAtomically(const std::wstring& path, const BYTE* data, DWORD length) {
  static std::atomic<uint64_t> sequence{0};
  std::wstring temporary;
  HANDLE file = INVALID_HANDLE_VALUE;
  for (int attempt = 0; attempt < 10; ++attempt) {
    temporary = path + L".tmp." + std::to_wstring(GetCurrentProcessId()) +
                L"." + std::to_wstring(GetTickCount64()) + L"." +
                std::to_wstring(sequence.fetch_add(1));
    file = CreateFileW(temporary.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_NEW,
                       FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file != INVALID_HANDLE_VALUE) break;
    const DWORD error = GetLastError();
    if (error != ERROR_FILE_EXISTS && error != ERROR_ALREADY_EXISTS) return error;
  }
  if (file == INVALID_HANDLE_VALUE) return ERROR_FILE_EXISTS;

  DWORD written = 0;
  DWORD error = ERROR_SUCCESS;
  if (!WriteFile(file, data, length, &written, nullptr)) {
    error = GetLastError();
  } else if (written != length) {
    error = ERROR_WRITE_FAULT;
  } else if (!FlushFileBuffers(file)) {
    error = GetLastError();
  }
  if (!CloseHandle(file) && error == ERROR_SUCCESS) error = GetLastError();

  // Both paths are in the same directory. Never truncate the previous blob or
  // fall back to copy/delete; readers see either the old complete value or the
  // new complete value. Flush the encrypted temporary before replacing it.
  if (error == ERROR_SUCCESS &&
      !MoveFileExW(temporary.c_str(), path.c_str(),
                   MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) {
    error = GetLastError();
  }
  if (error != ERROR_SUCCESS) DeleteFileW(temporary.c_str());
  return error;
}

}  // namespace

ReadResult Read(const std::string& key) {
  std::wstring path;
  std::wstring directory;
  DWORD error = FilePath(key, &path, &directory);
  if (error != ERROR_SUCCESS) return {error, std::nullopt};

  HANDLE file = CreateFileW(path.c_str(), GENERIC_READ,
                            FILE_SHARE_READ | FILE_SHARE_DELETE, nullptr,
                            OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    error = GetLastError();
    return {IsMissing(error) ? ERROR_SUCCESS : error, std::nullopt};
  }
  LARGE_INTEGER size{};
  if (!GetFileSizeEx(file, &size)) {
    error = GetLastError();
  } else if (size.QuadPart <= 0 || size.QuadPart > kMaxEncryptedBytes) {
    error = ERROR_INVALID_DATA;
  }
  if (error != ERROR_SUCCESS) {
    CloseHandle(file);
    return {error, std::nullopt};
  }
  std::vector<BYTE> encrypted(static_cast<size_t>(size.QuadPart));
  DWORD read = 0;
  if (!ReadFile(file, encrypted.data(), static_cast<DWORD>(encrypted.size()),
                &read, nullptr)) {
    error = GetLastError();
  } else if (read != encrypted.size()) {
    error = ERROR_HANDLE_EOF;
  }
  CloseHandle(file);
  if (error != ERROR_SUCCESS) return {error, std::nullopt};

  DATA_BLOB input{static_cast<DWORD>(encrypted.size()), encrypted.data()};
  DATA_BLOB output{};
  if (!CryptUnprotectData(&input, nullptr, nullptr, nullptr, nullptr,
                          CRYPTPROTECT_UI_FORBIDDEN, &output)) {
    return {GetLastError(), std::nullopt};
  }
  std::string value;
  if (output.cbData != 0) {
    value.assign(reinterpret_cast<char*>(output.pbData), output.cbData);
  }
  LocalFree(output.pbData);
  return {ERROR_SUCCESS, std::move(value)};
}

DWORD Write(const std::string& key, const std::string& value) {
  if (value.size() > kMaxValueBytes) return ERROR_FILE_TOO_LARGE;
  std::wstring path;
  std::wstring directory;
  DWORD error = FilePath(key, &path, &directory);
  if (error != ERROR_SUCCESS) return error;
  if (!CreateDirectoryW(directory.c_str(), nullptr)) {
    error = GetLastError();
    if (error != ERROR_ALREADY_EXISTS) return error;
  }

  DATA_BLOB input{
      static_cast<DWORD>(value.size()),
      reinterpret_cast<BYTE*>(const_cast<char*>(value.data()))};
  DATA_BLOB output{};
  if (!CryptProtectData(&input, L"dry_eye_widget", nullptr, nullptr, nullptr,
                        CRYPTPROTECT_UI_FORBIDDEN, &output)) {
    return GetLastError();
  }
  error = WriteAtomically(path, output.pbData, output.cbData);
  LocalFree(output.pbData);
  return error;
}

DWORD Delete(const std::string& key) {
  std::wstring path;
  std::wstring directory;
  const DWORD error = FilePath(key, &path, &directory);
  if (error != ERROR_SUCCESS) return error;
  if (DeleteFileW(path.c_str())) return ERROR_SUCCESS;
  const DWORD delete_error = GetLastError();
  return IsMissing(delete_error) ? ERROR_SUCCESS : delete_error;
}

}  // namespace secure_store
