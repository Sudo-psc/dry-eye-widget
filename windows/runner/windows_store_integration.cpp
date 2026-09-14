// C++/WinRT uses exception-enabled STL locally; Flutter's other translation
// units retain their existing _HAS_EXCEPTIONS setting.
#ifdef _HAS_EXCEPTIONS
#undef _HAS_EXCEPTIONS
#endif
#define _HAS_EXCEPTIONS 1

#include "windows_store_integration.h"

#include <appmodel.h>
#include <roapi.h>
#include <winrt/Windows.ApplicationModel.h>
#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.UI.Notifications.h>

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <functional>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

namespace {
using flutter::EncodableMap;
using flutter::EncodableValue;
using MethodResult = flutter::MethodResult<EncodableValue>;
using winrt::Windows::ApplicationModel::StartupTask;
using winrt::Windows::ApplicationModel::StartupTaskState;
using winrt::Windows::UI::Notifications::NotificationSetting;
using winrt::Windows::UI::Notifications::ToastNotification;
using winrt::Windows::UI::Notifications::ToastNotificationManager;
using winrt::Windows::UI::Notifications::ToastNotifier;
using winrt::Windows::UI::Notifications::ToastTemplateType;

constexpr UINT kCompleteStoreOperation = WM_APP + 0x457;
constexpr wchar_t kStartupTaskId[] = L"DryEyeWidgetStartup";

bool HasPackageIdentity() {
  UINT32 length = 0;
  const LONG error = GetCurrentPackageFullName(&length, nullptr);
  if (error == APPMODEL_ERROR_NO_PACKAGE) return false;
  if (error != ERROR_INSUFFICIENT_BUFFER) {
    winrt::throw_hresult(HRESULT_FROM_WIN32(error));
  }
  return true;
}

winrt::hstring CurrentApplicationId() {
  UINT32 length = 0;
  LONG error = GetCurrentApplicationUserModelId(&length, nullptr);
  if (error != ERROR_INSUFFICIENT_BUFFER) {
    winrt::throw_hresult(HRESULT_FROM_WIN32(error));
  }
  std::vector<wchar_t> value(length);
  error = GetCurrentApplicationUserModelId(&length, value.data());
  if (error != ERROR_SUCCESS) {
    winrt::throw_hresult(HRESULT_FROM_WIN32(error));
  }
  return winrt::hstring(value.data());
}

bool StartupEnabled(StartupTaskState state) {
  return state == StartupTaskState::Enabled ||
         state == StartupTaskState::EnabledByPolicy;
}

void ReportFailure(const std::shared_ptr<MethodResult>& result,
                   const winrt::hresult_error& error) {
  result->Error("windows_store_error", "Windows package API failed",
                EncodableValue(static_cast<int32_t>(error.code())));
}

// WinRT completion delegates may run on a worker thread. Keep replies and
// RequestEnableAsync on the Flutter platform thread. The shared queue outlives
// pending delegates, but stops accepting work before engine teardown.
struct CompletionQueue {
  explicit CompletionQueue(HWND target) : window(target) {}

  void Post(std::function<void()> callback) {
    std::lock_guard<std::mutex> lock(mutex);
    if (!alive) return;
    callbacks.push_back(std::move(callback));
    if (!PostMessage(window, kCompleteStoreOperation, 0, 0)) {
      callbacks.pop_back();
    }
  }

  void Drain() {
    std::vector<std::function<void()>> ready;
    {
      std::lock_guard<std::mutex> lock(mutex);
      ready.swap(callbacks);
    }
    for (auto& callback : ready) callback();
  }

  void Close() {
    std::lock_guard<std::mutex> lock(mutex);
    alive = false;
    callbacks.clear();
  }

  HWND window;
  std::mutex mutex;
  bool alive = true;
  std::vector<std::function<void()>> callbacks;
};

void QueryStartup(const std::shared_ptr<CompletionQueue>& queue,
                  const std::shared_ptr<MethodResult>& result,
                  bool change, bool enable) {
  StartupTask::GetAsync(kStartupTaskId).Completed(
      [queue, result, change, enable](const auto& operation, auto) {
        try {
          auto task = operation.GetResults();
          queue->Post([queue, result, task, change, enable]() {
            try {
              if (!change) {
                result->Success(EncodableValue(StartupEnabled(task.State())));
                return;
              }
              if (!enable) {
                task.Disable();
                result->Success(EncodableValue(StartupEnabled(task.State())));
                return;
              }
              // Windows preserves DisabledByUser/DisabledByPolicy; never
              // override those choices using registry or startup shortcuts.
              task.RequestEnableAsync().Completed(
                  [queue, result](const auto& request_operation, auto) {
                    try {
                      const bool enabled =
                          StartupEnabled(request_operation.GetResults());
                      queue->Post([result, enabled]() {
                        result->Success(EncodableValue(enabled));
                      });
                    } catch (const winrt::hresult_error& error) {
                      queue->Post([result, error]() { ReportFailure(result, error); });
                    }
                  });
            } catch (const winrt::hresult_error& error) {
              ReportFailure(result, error);
            }
          });
        } catch (const winrt::hresult_error& error) {
          queue->Post([result, error]() { ReportFailure(result, error); });
        }
      });
}
}  // namespace

class WindowsStoreIntegration::Impl {
 public:
  Impl(flutter::BinaryMessenger* messenger, HWND window)
      : queue_(std::make_shared<CompletionQueue>(window)),
        channel_(messenger, "dry_eye_widget/windows_store",
                 &flutter::StandardMethodCodec::GetInstance()),
        runtime_status_(RoInitialize(RO_INIT_SINGLETHREADED)) {
    channel_.SetMethodCallHandler([this](const auto& call, auto result) {
      HandleCall(call, std::move(result));
    });
  }

  ~Impl() {
    channel_.SetMethodCallHandler(nullptr);
    queue_->Close();
    notifier_ = nullptr;
    if (SUCCEEDED(runtime_status_)) RoUninitialize();
  }

  bool HandleMessage(UINT message) {
    if (message != kCompleteStoreOperation) return false;
    queue_->Drain();
    return true;
  }

 private:
  void HandleCall(const flutter::MethodCall<EncodableValue>& call,
                  std::shared_ptr<MethodResult> result) {
    try {
      const bool packaged = HasPackageIdentity();
      if (call.method_name() == "isPackaged") {
        result->Success(EncodableValue(packaged));
        return;
      }
      if (!packaged) {
        result->Error("not_packaged", "This API requires an MSIX package");
        return;
      }
      winrt::check_hresult(runtime_status_);
      if (call.method_name() == "initializeNotifications") {
        // Use the OS AUMID, not the display name or a guessed package family.
        notifier_ = ToastNotificationManager::CreateToastNotifier(CurrentApplicationId());
        result->Success(EncodableValue(true));
      } else if (call.method_name() == "showNotification") {
        const auto* args = call.arguments()
                               ? std::get_if<EncodableMap>(call.arguments())
                               : nullptr;
        if (!args || !notifier_) {
          result->Error("invalid_state", "Notification service is not initialized");
          return;
        }
        auto title_it = args->find(EncodableValue("title"));
        auto body_it = args->find(EncodableValue("body"));
        const auto* title = title_it == args->end()
                                ? nullptr : std::get_if<std::string>(&title_it->second);
        const auto* body = body_it == args->end()
                               ? nullptr : std::get_if<std::string>(&body_it->second);
        if (!title || !body) {
          result->Error("invalid_arguments", "Expected notification title and body");
          return;
        }
        if (notifier_.Setting() != NotificationSetting::Enabled) {
          result->Error("notifications_disabled", "Notifications are disabled by Windows");
          return;
        }
        auto xml = ToastNotificationManager::GetTemplateContent(ToastTemplateType::ToastText02);
        auto nodes = xml.GetElementsByTagName(L"text");
        nodes.Item(0).AppendChild(xml.CreateTextNode(winrt::to_hstring(*title)));
        nodes.Item(1).AppendChild(xml.CreateTextNode(winrt::to_hstring(*body)));
        notifier_.Show(ToastNotification(xml));
        result->Success(EncodableValue(true));
      } else if (call.method_name() == "getStartupEnabled") {
        QueryStartup(queue_, result, false, false);
      } else if (call.method_name() == "setStartupEnabled") {
        const auto* enabled = call.arguments()
                                  ? std::get_if<bool>(call.arguments()) : nullptr;
        if (!enabled) {
          result->Error("invalid_arguments", "Expected startup enabled boolean");
          return;
        }
        QueryStartup(queue_, result, true, *enabled);
      } else {
        result->NotImplemented();
      }
    } catch (const winrt::hresult_error& error) {
      ReportFailure(result, error);
    } catch (const std::exception&) {
      result->Error("windows_store_error", "Windows package operation failed");
    }
  }

  std::shared_ptr<CompletionQueue> queue_;
  flutter::MethodChannel<EncodableValue> channel_;
  HRESULT runtime_status_;
  ToastNotifier notifier_{nullptr};
};

WindowsStoreIntegration::WindowsStoreIntegration(
    flutter::BinaryMessenger* messenger, HWND window)
    : impl_(std::make_unique<Impl>(messenger, window)) {}

WindowsStoreIntegration::~WindowsStoreIntegration() = default;

bool WindowsStoreIntegration::HandleMessage(UINT message) {
  return impl_->HandleMessage(message);
}
