#ifndef FLUTTER_PLUGIN_WINDOW_PROC_DELEGATE_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_WINDOW_PROC_DELEGATE_PLUGIN_C_API_H_

#include <flutter_plugin_registrar.h>
#include <stdint.h>
#include <windows.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

// Forward declaration
namespace window_proc_delegate {
struct WindowsMessage;
}

#if defined(__cplusplus)
extern "C" {
#endif

// Callback signature for Dart WindowProc delegate
typedef void (*DartWindowProcCallbackC)(window_proc_delegate::WindowsMessage* message);

FLUTTER_PLUGIN_EXPORT void WindowProcDelegatePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

FLUTTER_PLUGIN_EXPORT void WindowProcDelegateSetCallback(
    DartWindowProcCallbackC callback);

FLUTTER_PLUGIN_EXPORT intptr_t WindowProcDelegateInitDartApi(void* data);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_WINDOW_PROC_DELEGATE_PLUGIN_C_API_H_
