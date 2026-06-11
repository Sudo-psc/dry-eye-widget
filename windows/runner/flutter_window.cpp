#include "flutter_window.h"

#include <windows.h>
#include <dpapi.h>

#include <memory>
#include <optional>
#include <string>
#include <vector>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"

#pragma comment(lib, "Crypt32.lib")

namespace {

// Caminho do arquivo cifrado para uma dada chave, em %APPDATA%\dry_eye_widget.
std::wstring SecureFilePath(const std::string& key) {
  wchar_t appdata[MAX_PATH] = {0};
  DWORD n = GetEnvironmentVariableW(L"APPDATA", appdata, MAX_PATH);
  std::wstring dir = std::wstring(appdata, n) + L"\\dry_eye_widget";
  CreateDirectoryW(dir.c_str(), nullptr);
  std::wstring wkey(key.begin(), key.end());
  return dir + L"\\" + wkey + L".bin";
}

bool WriteAllBytes(const std::wstring& path, const BYTE* data, DWORD len) {
  HANDLE h = CreateFileW(path.c_str(), GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS,
                         FILE_ATTRIBUTE_NORMAL, nullptr);
  if (h == INVALID_HANDLE_VALUE) return false;
  DWORD written = 0;
  bool ok = WriteFile(h, data, len, &written, nullptr) && written == len;
  CloseHandle(h);
  return ok;
}

std::vector<BYTE> ReadAllBytes(const std::wstring& path, bool* ok) {
  *ok = false;
  HANDLE h = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ, nullptr,
                         OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (h == INVALID_HANDLE_VALUE) return {};
  DWORD size = GetFileSize(h, nullptr);
  std::vector<BYTE> buf(size);
  DWORD read = 0;
  *ok = ReadFile(h, buf.data(), size, &read, nullptr) && read == size;
  CloseHandle(h);
  return buf;
}

std::string ArgString(const flutter::EncodableMap* args, const char* key) {
  if (!args) return "";
  auto it = args->find(flutter::EncodableValue(std::string(key)));
  if (it == args->end()) return "";
  if (const auto* s = std::get_if<std::string>(&it->second)) return *s;
  return "";
}

// Timer que reafirma HWND_TOPMOST: apps em tela cheia (borderless) retomam o
// topo do z-order e escondem o widget; reposicionar periodicamente dentro da
// banda topmost mantém a janela visível. Tela cheia exclusiva (DirectX
// fullscreen real) não pode ser sobreposta por nenhuma janela.
constexpr UINT_PTR kTopMostTimerId = 0xD0E0;
constexpr UINT kTopMostIntervalMs = 2000;

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Canal de tempo ocioso do sistema (segundos desde a última entrada do
  // usuário em todo o sistema, via GetLastInputInfo).
  idle_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(), "dry_eye_widget/idle",
          &flutter::StandardMethodCodec::GetInstance());
  idle_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        if (call.method_name() == "idleSeconds") {
          LASTINPUTINFO lii;
          lii.cbSize = sizeof(LASTINPUTINFO);
          double idle = 0.0;
          if (GetLastInputInfo(&lii)) {
            idle = (GetTickCount() - lii.dwTime) / 1000.0;
          }
          result->Success(flutter::EncodableValue(idle));
        } else {
          result->NotImplemented();
        }
      });

  // Canal de armazenamento seguro: cifra o blob com DPAPI (chave do usuário do
  // Windows) e o grava em %APPDATA%\dry_eye_widget. Apenas estado agregado.
  secure_store_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "dry_eye_widget/secure_store",
          &flutter::StandardMethodCodec::GetInstance());
  secure_store_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
             result) {
        const auto* args =
            std::get_if<flutter::EncodableMap>(call.arguments());
        std::string key = ArgString(args, "key");
        if (key.empty()) {
          result->Error("bad_args", "key ausente");
          return;
        }
        std::wstring path = SecureFilePath(key);
        const std::string& method = call.method_name();
        if (method == "write") {
          std::string value = ArgString(args, "value");
          DATA_BLOB in;
          in.pbData = reinterpret_cast<BYTE*>(value.data());
          in.cbData = static_cast<DWORD>(value.size());
          DATA_BLOB out;
          if (CryptProtectData(&in, L"dry_eye_widget", nullptr, nullptr,
                               nullptr, 0, &out)) {
            WriteAllBytes(path, out.pbData, out.cbData);
            LocalFree(out.pbData);
          }
          result->Success();
        } else if (method == "read") {
          bool ok = false;
          std::vector<BYTE> enc = ReadAllBytes(path, &ok);
          if (!ok || enc.empty()) {
            result->Success();  // null
            return;
          }
          DATA_BLOB in;
          in.pbData = enc.data();
          in.cbData = static_cast<DWORD>(enc.size());
          DATA_BLOB out;
          if (CryptUnprotectData(&in, nullptr, nullptr, nullptr, nullptr, 0,
                                 &out)) {
            std::string value(reinterpret_cast<char*>(out.pbData), out.cbData);
            LocalFree(out.pbData);
            result->Success(flutter::EncodableValue(value));
          } else {
            result->Success();  // null
          }
        } else if (method == "delete") {
          DeleteFileW(path.c_str());
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  SetTimer(GetHandle(), kTopMostTimerId, kTopMostIntervalMs, nullptr);

  return true;
}

void FlutterWindow::OnDestroy() {
  KillTimer(GetHandle(), kTopMostTimerId);
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_TIMER:
      if (wparam == kTopMostTimerId) {
        // SWP_NOACTIVATE evita roubar o foco do app em primeiro plano.
        if (IsWindowVisible(hwnd)) {
          SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0,
                       SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        }
        return 0;
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
