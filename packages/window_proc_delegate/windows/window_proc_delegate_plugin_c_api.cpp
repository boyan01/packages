#include "include/window_proc_delegate/window_proc_delegate_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>
#include "dart_api_dl.h"

#include "window_proc_delegate_plugin.h"

namespace {
window_proc_delegate::WindowProcDelegatePlugin* g_plugin = nullptr;
DartWindowProcCallbackC g_dart_callback = nullptr;
Dart_Isolate g_dart_isolate = nullptr;

// RAII helper for Dart isolate scope
class DartIsolateScope {
 public:
  explicit DartIsolateScope(Dart_Isolate isolate) : isolate_(isolate) {
    previous_ = Dart_CurrentIsolate_DL();
    if (previous_ == isolate_) {
      return;
    }
    if (previous_) {
      Dart_ExitIsolate_DL();
    }
    if (isolate_) {
      Dart_EnterIsolate_DL(isolate_);
    }
  }

  ~DartIsolateScope() {
    Dart_Isolate current = Dart_CurrentIsolate_DL();
    if (previous_ == isolate_) {
      return;
    }
    if (current) {
      Dart_ExitIsolate_DL();
    }
    if (previous_) {
      Dart_EnterIsolate_DL(previous_);
    }
  }

  // Disallow copy and assign
  DartIsolateScope(const DartIsolateScope&) = delete;
  DartIsolateScope& operator=(const DartIsolateScope&) = delete;

 private:
  Dart_Isolate isolate_;
  Dart_Isolate previous_;
};

// Wrapper function that converts between C and C++ callback signatures
int32_t CppCallbackWrapper(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam, LRESULT* result) {
  if (g_dart_callback && g_dart_isolate) {
    // Enter the Dart isolate before calling the callback
    DartIsolateScope isolate_scope(g_dart_isolate);
    
    int64_t result_value = 0;
    int32_t handled = g_dart_callback(
        reinterpret_cast<intptr_t>(hwnd), 
        static_cast<uint32_t>(message), 
        static_cast<uint64_t>(wparam), 
        static_cast<int64_t>(lparam), 
        &result_value);
    if (handled && result) {
      *result = static_cast<LRESULT>(result_value);
    }
    return handled;
  }
  return 0;
}
}

void WindowProcDelegatePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  window_proc_delegate::WindowProcDelegatePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar),
      &g_plugin);
}

void WindowProcDelegateSetCallback(DartWindowProcCallbackC callback) {
  g_dart_callback = callback;
  
  // Record current Dart isolate when setting the callback
  if (callback) {
    g_dart_isolate = Dart_CurrentIsolate_DL();
  } else {
    g_dart_isolate = nullptr;
  }
  
  if (g_plugin) {
    if (callback) {
      g_plugin->SetDartCallback(CppCallbackWrapper);
    } else {
      g_plugin->SetDartCallback(nullptr);
    }
  }
}

intptr_t WindowProcDelegateInitDartApi(void* data) {
  return Dart_InitializeApiDL(data);
}
