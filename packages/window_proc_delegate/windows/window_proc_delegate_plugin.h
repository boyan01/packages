#ifndef FLUTTER_PLUGIN_WINDOW_PROC_DELEGATE_PLUGIN_H_
#define FLUTTER_PLUGIN_WINDOW_PROC_DELEGATE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
#include <optional>

namespace window_proc_delegate {

// Windows message structure
struct WindowsMessage {
  int64_t viewId;
  intptr_t windowHandle;
  int32_t message;
  int64_t wParam;
  int64_t lParam;
  int64_t lResult;
  bool handled;
};

// Callback signature for Dart WindowProc delegate
typedef void (*DartWindowProcCallback)(WindowsMessage* message);

class WindowProcDelegatePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar,
                                     WindowProcDelegatePlugin** out_plugin = nullptr);

  WindowProcDelegatePlugin(flutter::PluginRegistrarWindows* registrar);

  virtual ~WindowProcDelegatePlugin();

  // Disallow copy and assign.
  WindowProcDelegatePlugin(const WindowProcDelegatePlugin&) = delete;
  WindowProcDelegatePlugin& operator=(const WindowProcDelegatePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Set the Dart callback function pointer
  void SetDartCallback(DartWindowProcCallback callback);

  private:
    flutter::PluginRegistrarWindows* registrar_;
    int window_proc_delegate_id_;
    DartWindowProcCallback dart_callback_;
};

}  // namespace window_proc_delegate

#endif  // FLUTTER_PLUGIN_WINDOW_PROC_DELEGATE_PLUGIN_H_
