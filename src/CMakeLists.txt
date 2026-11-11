# Generate DBus interfaces
qt_add_dbus_interfaces(
	dbus_srcs
	${CMAKE_CURRENT_SOURCE_DIR}/mce.xml
)

qt_add_dbus_interfaces(
	dbus_srcs
	${CMAKE_CURRENT_SOURCE_DIR}/VolumeControl2.xml
)

set(
	SRC
	main.cpp
	mceconfigvalue.cpp
	sysinfo.cpp
	taptowake.cpp
	tilttowake.cpp
	volumecontrol.cpp
	${dbus_srcs}
)
set(
	HEADERS
	mceconfigvalue.h
	sysinfo.h
	taptowake.h
	tilttowake.h
	volumecontrol.h
)

add_library(asteroid-settings ${SRC} ${HEADERS})
asteroid_app_qml_module(asteroid-settings
	qml/main.qml
	qml/SettingsPage.qml
	qml/SettingsChip.qml
	qml/SettingsCategory.qml
	qml/SettingsText.qml
	qml/SettingsSlider.qml
	qml/ConfirmDialog.qml
	qml/ModeState.qml
	qml/ChoiceList.qml
	qml/ChoicePage.qml
	qml/ConnectivityPage.qml
	qml/BluetoothPage.qml
	qml/WiFiPage.qml
	qml/WiFiNetworksPage.qml
	qml/WiFiSavedPage.qml
	qml/WiFiSavedNetworkPage.qml
	qml/WiFiCurrentNetworkPage.qml
	qml/WiFiConnectionDialog.qml
	qml/DisplayPage.qml
	qml/BrightnessPage.qml
	qml/ExtraDimPage.qml
	qml/NightstandPage.qml
	qml/NightstandWatchfacePage.qml
	qml/StylePage.qml
	qml/WallpaperPage.qml
	qml/WatchfacePage.qml
	qml/WatchfaceSelector.qml
	qml/GesturesPage.qml
	qml/AppsPage.qml
	qml/DndPage.qml
	qml/AssistantPage.qml
	qml/SoundPage.qml
	qml/VibrationPage.qml
	qml/BatteryPage.qml
	qml/GeneralPage.qml
	qml/QuickPanelPage.qml
	qml/LauncherPage.qml
	qml/SystemPage.qml
	qml/UpdatesPage.qml
	qml/DateTimePage.qml
	qml/TimePage.qml
	qml/DatePage.qml
	qml/TimezonePage.qml
	qml/LanguagePage.qml
	qml/AboutPage.qml
	qml/VersionsPage.qml
	qml/DeveloperPage.qml
	qml/PageReady.js
	qml/ButtonsPage.qml
	qml/ModesPage.qml
	qml/LocationPage.qml
	qml/AccessibilityPage.qml
	qml/SecurityPage.qml
	qml/DisplaySizePage.qml
)
message(${CMAKE_CURRENT_BINARY_DIR})
target_include_directories(
	asteroid-settings
	PRIVATE
	${GENERATED_DBUS_HEADERS_DIR}
)
set_target_properties(asteroid-settings PROPERTIES PREFIX "")

target_link_libraries(
	asteroid-settings
	PRIVATE
		Qt::Qml
		Qt::Quick
		Qt::DBus
		PkgConfig::NGF
		Asteroid::AsteroidApp6
)

install(
	TARGETS asteroid-settings
	DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# the Settings list icons (drawn for eos to the stock shapes, settings-a-07),
# in the app's own data dir (packaged with it); main.qml names them for
# org.asteroid.controls Icon relative to /usr/share/icons/asteroid
install(
	FILES
		icons/eos-settings-accessibility.svg
		icons/eos-settings-battery.svg
		icons/eos-settings-buttons.svg
		icons/eos-settings-connectivity.svg
		icons/eos-settings-gestures.svg
		icons/eos-settings-location.svg
		icons/eos-settings-modes.svg
		icons/eos-settings-security.svg
		icons/eos-settings-system.svg
	DESTINATION ${CMAKE_INSTALL_DATADIR}/asteroid-settings/icons
)
