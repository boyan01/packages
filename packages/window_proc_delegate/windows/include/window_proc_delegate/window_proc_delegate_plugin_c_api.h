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

#if defined(__cplusplus)
extern "C" {
#endif

// Callback signature for Dart WindowProc delegate
// Returns 1 if the message was handled, 0 otherwise
typedef int32_t (*DartWindowProcCallbackC)(intptr_t hwnd, uint32_t message, 
                                           uint64_t wparam, int64_t lparam,
                                           int64_t* result);

FLUTTER_PLUGIN_EXPORT void WindowProcDelegatePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

FLUTTER_PLUGIN_EXPORT void WindowProcDelegateSetCallback(
    DartWindowProcCallbackC callback);

FLUTTER_PLUGIN_EXPORT intptr_t WindowProcDelegateInitDartApi(void* data);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_WINDOW_PROC_DELEGATE_PLUGIN_C_API_H_
