#include "window_proc_delegate_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <optional>
#include <sstream>

namespace window_proc_delegate {

// static
void WindowProcDelegatePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar,
    WindowProcDelegatePlugin** out_plugin) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "window_proc_delegate",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WindowProcDelegatePlugin>(registrar);
  
  // Store pointer if requested
  if (out_plugin) {
    *out_plugin = plugin.get();
  }

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WindowProcDelegatePlugin::WindowProcDelegatePlugin(flutter::PluginRegistrarWindows *registrar)
    : registrar_(registrar), dart_callback_(nullptr) {
  window_proc_delegate_id_ = registrar->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam) -> std::optional<LRESULT> {
        if (dart_callback_) {
          LRESULT result = 0;
          int32_t handled = dart_callback_(hwnd, message, wparam, lparam, &result);
          if (handled) {
            return result;
          }
        }
        return std::nullopt;
      });
}

WindowProcDelegatePlugin::~WindowProcDelegatePlugin() {
  registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_delegate_id_);
}

void WindowProcDelegatePlugin::SetDartCallback(DartWindowProcCallback callback) {
  dart_callback_ = callback;
}

void WindowProcDelegatePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("getPlatformVersion") == 0) {
    std::ostringstream version_stream;
    version_stream << "Windows ";
    if (IsWindows10OrGreater()) {
      version_stream << "10+";
    } else if (IsWindows8OrGreater()) {
      version_stream << "8";
    } else if (IsWindows7OrGreater()) {
      version_stream << "7";
    }
    result->Success(flutter::EncodableValue(version_stream.str()));
  } else {
    result->NotImplemented();
  }
}

}  // namespace window_proc_delegate
