#include "window_proc_delegate_plugin.h"

#include "include/window_proc_delegate/window_proc_delegate_plugin_c_api.h"

// This must be included before many other Windows headers.
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>
#include <optional>
#include <sstream>

namespace window_proc_delegate {

// static
void WindowProcDelegatePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "window_proc_delegate",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<WindowProcDelegatePlugin>(registrar);

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto& call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

WindowProcDelegatePlugin::WindowProcDelegatePlugin(
    flutter::PluginRegistrarWindows* registrar)
    : registrar_(registrar), engine_id_(0) {
  window_proc_delegate_id_ = registrar->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam,
             LPARAM lparam) -> std::optional<LRESULT> {
        // Get the callback for this engine's ID
        auto callback = GetCallbackForEngine(engine_id_);
        if (callback) {
          WindowsMessage msg = {};
          msg.windowHandle = reinterpret_cast<intptr_t>(hwnd);
          msg.message = static_cast<int32_t>(message);
          msg.wParam = static_cast<int64_t>(wparam);
          msg.lParam = static_cast<int64_t>(lparam);
          msg.lResult = 0;
          msg.handled = false;

          callback(&msg);

          if (msg.handled) {
            return static_cast<LRESULT>(msg.lResult);
          }
        }
        return std::nullopt;
      });
}

WindowProcDelegatePlugin::~WindowProcDelegatePlugin() {
  registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_delegate_id_);
}

void WindowProcDelegatePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("setEngineId") == 0) {
    const auto* arguments =
        std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (arguments) {
      auto engine_id_it = arguments->find(flutter::EncodableValue("engineId"));
      if (engine_id_it != arguments->end()) {
        engine_id_ = std::get<int64_t>(engine_id_it->second);
        result->Success();
        return;
      }
    }
    result->Error("INVALID_ARGUMENTS",
                  "Missing or invalid 'engineId' argument");
  } else {
    result->NotImplemented();
  }
}

}  // namespace window_proc_delegate
