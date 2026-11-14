/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "hiddenwifi.h"

#include <QByteArray>
#include <QDBusMessage>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QVariantMap>

HiddenWifi::HiddenWifi(QObject *parent)
    : QObject(parent)
    , m_bus(QDBusConnection::systemBus())
    , m_service(QStringLiteral("net.connman"))
{
}

void HiddenWifi::setConnection(const QDBusConnection &bus, const QString &service)
{
    m_bus = bus;
    m_service = service;
}

void HiddenWifi::connectNetwork(const QString &ssid, const QString &security, const QString &passphrase)
{
    if (m_busy)
        return;
    const QString sec = (security == QLatin1String("psk") || security == QLatin1String("wep")) ? security : QStringLiteral("none");
    if (ssid.isEmpty() || ssid.toUtf8().size() > 32 || (sec == QLatin1String("psk") && passphrase.size() < 8)) {
        emit finished(false, QStringLiteral("net.connman.Error.InvalidArguments"));
        return;
    }
    QVariantMap specs;
    specs.insert(QStringLiteral("Type"), QStringLiteral("wifi"));
    specs.insert(QStringLiteral("SSID"), ssid.toUtf8());
    specs.insert(QStringLiteral("Security"), sec);
    if (sec != QLatin1String("none"))
        specs.insert(QStringLiteral("Passphrase"), passphrase);
    QDBusMessage m = QDBusMessage::createMethodCall(m_service, QStringLiteral("/"), QStringLiteral("net.connman.Manager"),
                                                    QStringLiteral("ConnectService"));
    m << specs;
    m_busy = true;
    emit busyChanged();
    // connman answers when the connect is done or failed: it can take a while
    auto *w = new QDBusPendingCallWatcher(m_bus.asyncCall(m, 120000), this);
    connect(w, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *watcher) {
        watcher->deleteLater();
        const bool ok = !watcher->isError();
        const QString err = ok ? QString() : watcher->error().name();
        m_busy = false;
        emit busyChanged();
        emit finished(ok, err);
    });
}
