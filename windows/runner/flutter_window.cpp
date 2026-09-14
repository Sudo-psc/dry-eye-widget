#include "flutter_window.h"

#include <windows.h>

#include <cstdint>
#include <memory>
#include <optional>
#include <string>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include "flutter/generated_plugin_registrant.h"
#include "secure_store_windows.h"
#include "windows_store_integration.h"

namespace {

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
  store_integration_ = std::make_unique<WindowsStoreIntegration>(
      flutter_controller_->engine()->messenger(), GetHandle());

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
            call.arguments()
                ? std::get_if<flutter::EncodableMap>(call.arguments())
                : nullptr;
        std::string key = ArgString(args, "key");
        if (key.empty()) {
          result->Error("bad_args", "key ausente");
          return;
        }
        const std::string& method = call.method_name();
        DWORD error = ERROR_SUCCESS;
        if (method == "write") {
          std::string value = ArgString(args, "value");
          error = secure_store::Write(key, value);
        } else if (method == "read") {
          const auto stored = secure_store::Read(key);
          error = stored.error;
          if (error == ERROR_SUCCESS) {
            if (stored.value) {
              result->Success(flutter::EncodableValue(*stored.value));
            } else {
              result->Success();  // A missing key is null, not an error.
            }
            return;
          }
        } else if (method == "delete") {
          error = secure_store::Delete(key);
        } else {
          result->NotImplemented();
          return;
        }
        if (error != ERROR_SUCCESS) {
          // Do not include the path, key or stored contents in diagnostics.
          result->Error("secure_store_error",
                        "Windows secure storage " + method + " failed",
                        flutter::EncodableValue(static_cast<int64_t>(error)));
        } else {
          result->Success();
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
  store_integration_.reset();
  idle_channel_.reset();
  secure_store_channel_.reset();
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (store_integration_ && store_integration_->HandleMessage(message)) return 0;
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
