#include "include/window_proc_delegate/window_proc_delegate_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "window_proc_delegate_plugin.h"

void WindowProcDelegatePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  window_proc_delegate::WindowProcDelegatePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
