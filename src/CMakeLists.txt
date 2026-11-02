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
	qml/Toast.qml
	qml/ChoiceList.qml
	qml/ChoicePage.qml
	qml/ConnectivityPage.qml
	qml/BluetoothPage.qml
	qml/WiFiPage.qml
	qml/WiFiNetworksPage.qml
	qml/WiFiConnectionDialog.qml
	qml/DisplayPage.qml
	qml/BrightnessPage.qml
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
