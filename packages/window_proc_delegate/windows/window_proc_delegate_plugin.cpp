#include "window_proc_delegate_plugin.h"

#include "dart/dart_api_dl.h"
#include "include/window_proc_delegate/window_proc_delegate_plugin_c_api.h"
// This must be included before many other Windows headers.
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <map>
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
    : registrar_(registrar) {
  window_proc_delegate_id_ = registrar->RegisterTopLevelWindowProcDelegate(
      [this](HWND hwnd, UINT message, WPARAM wparam,
             LPARAM lparam) -> std::optional<LRESULT> {
        auto callback = GetCallback();
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
  if (engine_id_.has_value()) {
    UnregisterPlugin(*engine_id_);
  }
  registrar_->UnregisterTopLevelWindowProcDelegate(window_proc_delegate_id_);
}

void WindowProcDelegatePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (method_call.method_name().compare("setEngineId") == 0) {
    const auto* arguments = method_call.arguments();
    auto engine_id = arguments->LongValue();
    engine_id_ = engine_id;
    RegisterPlugin(engine_id, this);
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void WindowProcDelegatePlugin::SetCallback(DartWindowProcCallbackC callback,
                                           Dart_Isolate isolate) {
  std::lock_guard<std::mutex> lock(mutex_);
  callback_ = callback;
  isolate_ = isolate;
}

DartWindowProcCallback WindowProcDelegatePlugin::GetCallback() {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!callback_ || !isolate_) {
    return nullptr;
  }

  return [callback = callback_, isolate = isolate_](WindowsMessage* message) {
    // Enter the Dart isolate before calling the callback
    Dart_Isolate previous = Dart_CurrentIsolate_DL();
    if (previous != isolate) {
      if (previous) {
        Dart_ExitIsolate_DL();
      }
      Dart_EnterIsolate_DL(isolate);
    }

    callback(message);

    // Restore previous isolate
    Dart_Isolate current = Dart_CurrentIsolate_DL();
    if (previous != isolate) {
      if (current) {
        Dart_ExitIsolate_DL();
      }
      if (previous) {
        Dart_EnterIsolate_DL(previous);
      }
    }
  };
}

// Global state for plugin registration
namespace {
std::map<int64_t, WindowProcDelegatePlugin*> g_plugins;
std::map<int64_t, std::pair<DartWindowProcCallbackC, Dart_Isolate>>
    g_pending_callbacks;
std::mutex g_mutex;
}  // namespace

// static
void WindowProcDelegatePlugin::RegisterPlugin(
    int64_t engine_id, WindowProcDelegatePlugin* plugin) {
  std::lock_guard<std::mutex> lock(g_mutex);
  g_plugins[engine_id] = plugin;

  // Check for pending callbacks
  auto it = g_pending_callbacks.find(engine_id);
  if (it != g_pending_callbacks.end()) {
    plugin->SetCallback(it->second.first, it->second.second);
    g_pending_callbacks.erase(it);
  }
}

// static
void WindowProcDelegatePlugin::UnregisterPlugin(int64_t engine_id) {
  std::lock_guard<std::mutex> lock(g_mutex);
  g_plugins.erase(engine_id);
  g_pending_callbacks.erase(engine_id);
}

// static
void WindowProcDelegatePlugin::SetCallbackForEngine(
    int64_t engine_id, DartWindowProcCallbackC callback, Dart_Isolate isolate) {
  std::lock_guard<std::mutex> lock(g_mutex);
  if (g_plugins.find(engine_id) != g_plugins.end()) {
    // Plugin already registered, set callback directly
    g_plugins[engine_id]->SetCallback(callback, isolate);
  } else {
    // Plugin not yet registered, store as pending
    if (callback) {
      g_pending_callbacks[engine_id] = std::make_pair(callback, isolate);
    } else {
      g_pending_callbacks.erase(engine_id);
    }
  }
}

}  // namespace window_proc_delegate

void WindowProcDelegateSetCallback(int64_t engineId,
                                   DartWindowProcCallbackC callback) {
  window_proc_delegate::WindowProcDelegatePlugin::SetCallbackForEngine(
      engineId, callback, Dart_CurrentIsolate_DL());
}

intptr_t WindowProcDelegateInitDartApi(void* data) {
  return Dart_InitializeApiDL(data);
}
