/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef HIDDENWIFI_H
#define HIDDENWIFI_H

#include <QDBusConnection>
#include <QObject>
#include <QString>

/*
 * Settings > Connectivity > Wi-Fi > Add network > Add hidden network
 * (connectivity-system-ux-12): connman's Manager.ConnectService with the
 * keys connman documents for a network that does not announce itself: Type
 * "wifi", SSID as a byte array (a QML string would go out as a string, which
 * connman does not take), Security ("none", "psk", "wep") and Passphrase.
 * connman then probes for the network, creates the service and connects it.
 * One call per tap, nothing runs in the background. The bus can be set, for
 * the unit test.
 */
class HiddenWifi : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit HiddenWifi(QObject *parent = nullptr);

    void setConnection(const QDBusConnection &bus, const QString &service = QStringLiteral("net.connman"));
    bool busy() const { return m_busy; }

    // security: "none", "psk" or "wep"; passphrase ignored for "none"
    Q_INVOKABLE void connectNetwork(const QString &ssid, const QString &security, const QString &passphrase);

signals:
    void busyChanged();
    // ok: connman took the request (the service shows in the Wi-Fi list and
    // connects); else error is connman's error name
    void finished(bool ok, const QString &error);

private:
    QDBusConnection m_bus;
    QString m_service;
    bool m_busy = false;
};

#endif // HIDDENWIFI_H
