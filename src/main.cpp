/*
 * Copyright (C) 2017 - Florent Revest <revestflo@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include <QElapsedTimer>
#include <QGuiApplication>
#include <QLoggingCategory>
#include <QQuickItem>
#include <QQuickView>
#include <QScreen>
#include <QTimer>
#include <QtQml>
#include <sys/utsname.h>

#include <asteroidapp.h>

#include "volumecontrol.h"
#include "tilttowake.h"
#include "taptowake.h"
#include "sysinfo.h"
#include "mceconfigvalue.h"
#include "appinventory.h"
#include "bluetoothdevices.h"
#include "hiddenwifi.h"
#include "packageinfo.h"
#include "timezonemodel.h"

// how long Settings takes to show (D60-46), one line in the journal per start
Q_LOGGING_CATEGORY(lcStart, "asteroid.settings.start", QtInfoMsg)

int main(int argc, char *argv[])
{
    QElapsedTimer started;
    started.start();
    utsname buf;
    uname(&buf);
    QScopedPointer<QGuiApplication> app(AsteroidApp::application(argc, argv));
    QScopedPointer<QQuickView> view(AsteroidApp::createView());
    qmlRegisterType<VolumeControl>("org.asteroid.settings", 1, 0, "VolumeControl");
    qmlRegisterType<TiltToWake>("org.asteroid.settings", 1, 0, "TiltToWake");
    qmlRegisterType<TapToWake>("org.asteroid.settings", 1, 0, "TapToWake");
    qmlRegisterType<SysInfo>("org.asteroid.settings", 1, 0, "SysInfo");
    qmlRegisterType<MceConfigValue>("org.asteroid.settings", 1, 0, "MceConfigValue");
    qmlRegisterType<TimeZoneModel>("org.asteroid.settings", 1, 0, "TimeZoneModel");
    qmlRegisterType<PackageInfo>("org.asteroid.settings", 1, 0, "PackageInfo");
    qmlRegisterType<AppInventory>("org.asteroid.settings", 1, 0, "AppInventory");
    qmlRegisterType<BluetoothDevices>("org.asteroid.settings", 1, 0, "BluetoothDevices");
    qmlRegisterType<HiddenWifi>("org.asteroid.settings", 1, 0, "HiddenWifi");
    // the context properties before main.qml is made: set on a context in
    // use, they make it look again at every name it could not find
    view->rootContext()->setContextProperty("qtVersion", QString(qVersion()));
    view->rootContext()->setContextProperty("kernelVersion", QString(buf.release));
    view->setSource(QUrl("qrc:/Settings/qml/main.qml"));
    const qint64 qmlReady = started.elapsed();
    // main.qml (anchors.fill: parent) gets this size once the window is
    // shown, and makes its first screen then (main.qml makeFirstScreen())
    view->resize(app->primaryScreen()->size());
    // the first frame is on screen: main.qml makes its dialogs from now on
    // (firstFrameDrawn) and the journal gets the times since main(). The
    // render thread sends frameSwapped: queued to this thread, once.
    QObject::connect(view.data(), &QQuickWindow::frameSwapped, app.data(), [&view, &started, qmlReady]() {
        qCInfo(lcStart, "main.qml ready after %lld ms, first frame after %lld ms", qmlReady, started.elapsed());
        if (QObject *root = view->rootObject())
            root->setProperty("firstFrameDrawn", true);
    }, Qt::ConnectionType(Qt::QueuedConnection | Qt::SingleShotConnection));
    // the main list's rows below its first screen are made after the first
    // frame (main.qml): one more journal line once they are all in
    // (mainListMade: its notify signal starts a zero timer, which logs the
    // first time it finds it true)
    bool listLogged = false;
    if (QObject *root = view->rootObject()) {
        const int made = root->metaObject()->indexOfProperty("mainListMade");
        QTimer *listMade = new QTimer(view.data());
        listMade->setSingleShot(true);
        listMade->setInterval(0);
        QObject::connect(listMade, &QTimer::timeout, app.data(), [&view, &started, &listLogged]() {
            QObject *root = view->rootObject();
            if (!listLogged && root && root->property("mainListMade").toBool()) {
                listLogged = true;
                qCInfo(lcStart, "main list complete after %lld ms", started.elapsed());
            }
        });
        if (made >= 0) {
            const QMetaMethod start = listMade->metaObject()->method(listMade->metaObject()->indexOfSlot("start()"));
            QObject::connect(root, root->metaObject()->property(made).notifySignal(), listMade, start);
        }
    }
    view->show();
    return app->exec();
}
