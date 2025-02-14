#include "flutter_splendid_ble_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

namespace flutter_splendid_ble {
    /// @brief A Windows-specific implementation of the FlutterSplendidBlePlugin.
    ///
    /// This class registers a method channel and handles incoming method calls from the Dart side.
    class FlutterSplendidBlePlugin : public flutter::Plugin {
    public:
        /// @brief Registers this plugin with the given plugin registrar.
        ///
        /// This method creates the Method Channel, sets up the method call handler,
        /// and registers the plugin instance with Flutter.
        ///
        /// @param registrar A pointer to the Flutter plugin registrar for Windows.
        static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

        /// @brief Constructs a new FlutterSplendidBlePlugin instance.
        FlutterSplendidBlePlugin();

        /// @brief Destroys the FlutterSplendidBlePlugin instance.
        virtual ~FlutterSplendidBlePlugin();

    private:
        /// @brief Handles method calls from the Dart side.
        ///
        /// This method uses a switch-like structure (if-else statements) to decide how to
        /// handle each individual method call. Currently, each method returns a simple
        /// confirmation message. Actual implementations will be added later.
        ///
        /// @param method_call The method call sent from the Dart side.
        /// @param result A pointer to the MethodResult to send back the response.
        void HandleMethodCall(
                const flutter::MethodCall<flutter::EncodableValue>& method_call,
                std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
    };

    // static
    void FlutterSplendidBlePlugin::RegisterWithRegistrar(
            flutter::PluginRegistrarWindows* registrar) {
        // Create a MethodChannel for communicating with the Dart side of the plugin.
        auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
                registrar->messenger(), "flutter_splendid_ble_plugin",
                        &flutter::StandardMethodCodec::GetInstance());

        // Create an instance of the plugin.
        auto plugin = std::make_unique<FlutterSplendidBlePlugin>();

        // Set the Method Call handler for the channel.
        channel->SetMethodCallHandler(
                [plugin_pointer = plugin.get()](
                        const flutter::MethodCall<flutter::EncodableValue>& call,
                        std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
                    plugin_pointer->HandleMethodCall(call, std::move(result));
                });

        // Register the plugin with the Flutter plugin registrar.
        registrar->AddPlugin(std::move(plugin));
    }

    FlutterSplendidBlePlugin::FlutterSplendidBlePlugin() {
        // TODO: Initialize any Windows-specific resources required by the plugin.
    }

    FlutterSplendidBlePlugin::~FlutterSplendidBlePlugin() {
        // TODO: Clean up any resources allocated by the plugin.
    }

    void FlutterSplendidBlePlugin::HandleMethodCall(
            const flutter::MethodCall<flutter::EncodableValue>& method_call,
            std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        // Retrieve the method name from the call.
        std::string method_name = method_call.method_name();

        // Handle each method call using a simple if-else (switch-like) structure.
        if (method_name == "startScan") {
            // TODO: Implement the logic to start scanning for Bluetooth devices.
            result->Success(flutter::EncodableValue("startScan called"));
        } else if (method_name == "stopScan") {
            // TODO: Implement the logic to stop scanning for Bluetooth devices.
            result->Success(flutter::EncodableValue("stopScan called"));
        } else if (method_name == "connect") {
            // TODO: Implement the logic to connect to a Bluetooth device.
            result->Success(flutter::EncodableValue("connect called"));
        } else if (method_name == "disconnect") {
            // TODO: Implement the logic to disconnect from a Bluetooth device.
            result->Success(flutter::EncodableValue("disconnect called"));
        } else {
            // If the method is not implemented, notify the Dart side.
            result->NotImplemented();
        }
    }
}

/// @brief The entry point for registering the Windows plugin with the Flutter engine.
///
/// This function is called by the Flutter Windows embedding to register the plugin.
void FlutterSplendidBlePluginRegisterWithRegistrar(
        FlutterDesktopPluginRegistrarRef registrar) {
    flutter_splendid_ble_plugin::FlutterSplendidBlePlugin::RegisterWithRegistrar(
            flutter::PluginRegistrarManager::GetInstance()
                    ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
