#ifndef FLUTTER_PLUGIN_WINDOW_PROC_DELEGATE_PLUGIN_H_
#define FLUTTER_PLUGIN_WINDOW_PROC_DELEGATE_PLUGIN_H_
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <mutex>
#include <optional>

#include "dart/dart_api_dl.h"
#include "include/window_proc_delegate/window_proc_delegate_plugin_c_api.h"

namespace window_proc_delegate {

struct WindowsMessage {
  intptr_t windowHandle;
  int32_t message;
  int64_t wParam;
  int64_t lParam;
  int64_t lResult;
  bool handled;
};

}  // namespace window_proc_delegate

#if defined(__cplusplus)
extern "C" {
#endif

typedef void (*DartWindowProcCallbackC)(
    window_proc_delegate::WindowsMessage* message);

FLUTTER_PLUGIN_EXPORT void WindowProcDelegateSetCallback(
    int64_t engineId, DartWindowProcCallbackC callback);

FLUTTER_PLUGIN_EXPORT intptr_t WindowProcDelegateInitDartApi(void* data);

#if defined(__cplusplus)
}  // extern "C"
#endif

namespace window_proc_delegate {

typedef std::function<void(WindowsMessage*)> DartWindowProcCallback;

class WindowProcDelegatePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  WindowProcDelegatePlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~WindowProcDelegatePlugin();

  // Disallow copy and assign.
  WindowProcDelegatePlugin(const WindowProcDelegatePlugin&) = delete;
  WindowProcDelegatePlugin& operator=(const WindowProcDelegatePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  void SetCallback(DartWindowProcCallbackC callback, Dart_Isolate isolate);
  DartWindowProcCallback GetCallback();

  // Static methods for global registration
  static void RegisterPlugin(int64_t engine_id,
                             WindowProcDelegatePlugin* plugin);
  static void UnregisterPlugin(int64_t engine_id);
  static void SetCallbackForEngine(int64_t engine_id,
                                   DartWindowProcCallbackC callback,
                                   Dart_Isolate isolate);

 private:
  flutter::PluginRegistrarWindows* registrar_;
  int window_proc_delegate_id_;
  std::optional<int64_t> engine_id_;
  DartWindowProcCallbackC callback_ = nullptr;
  Dart_Isolate isolate_ = nullptr;
  std::mutex mutex_;
};

}  // namespace window_proc_delegate

#endif  // FLUTTER_PLUGIN_WINDOW_PROC_DELEGATE_PLUGIN_H_
