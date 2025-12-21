#include "include/window_proc_delegate/window_proc_delegate_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>
#include "dart_api_dl.h"
#include <map>
#include <utility>

#include "window_proc_delegate_plugin.h"

namespace {
// Global map to store callbacks and isolates for each engine
std::map<int64_t, std::pair<DartWindowProcCallbackC, Dart_Isolate>> g_callbacks;
}

void WindowProcDelegatePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  window_proc_delegate::WindowProcDelegatePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

void WindowProcDelegateSetCallback(int64_t engineId, DartWindowProcCallbackC callback) {
  if (callback) {
    // Store the callback and current isolate
    Dart_Isolate current_isolate = Dart_CurrentIsolate_DL();
    g_callbacks[engineId] = std::make_pair(callback, current_isolate);
  } else {
    // Remove the callback for this engine
    g_callbacks.erase(engineId);
  }
}

window_proc_delegate::DartWindowProcCallback GetCallbackForEngine(int64_t engineId) {
  auto it = g_callbacks.find(engineId);
  if (it == g_callbacks.end()) {
    return nullptr;
  }
  
  auto callback = it->second.first;
  auto isolate = it->second.second;
  
  // Return a lambda that handles isolate management
  return [callback, isolate](window_proc_delegate::WindowsMessage* message) {
    if (callback && isolate) {
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
    }
  };
}

intptr_t WindowProcDelegateInitDartApi(void* data) {
  return Dart_InitializeApiDL(data);
}
