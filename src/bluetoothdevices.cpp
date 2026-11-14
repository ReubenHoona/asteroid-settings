/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "bluetoothdevices.h"

#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDBusMetaType>
#include <QDBusPendingCall>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusServiceWatcher>
#include <QMetaObject>

#include <algorithm>

namespace {
const char kDevice[] = "org.bluez.Device1";
const char kAdapter[] = "org.bluez.Adapter1";
const char kProps[] = "org.freedesktop.DBus.Properties";
const char kManager[] = "org.freedesktop.DBus.ObjectManager";
// Pair() waits for the person at the other end: stock gives it as long as
// the phone's dialog needs
const int kPairTimeoutMs = 120000;
const int kConnectTimeoutMs = 30000;
}

BluetoothDevices::BluetoothDevices(QObject *parent)
    : QAbstractListModel(parent)
    , m_bus(QDBusConnection::systemBus())
    , m_service(QStringLiteral("org.bluez"))
{
    qDBusRegisterMetaType<BtInterfaceList>();
    qDBusRegisterMetaType<BtManagedObjects>();
    QMetaObject::invokeMethod(this, "init", Qt::QueuedConnection);
}

BluetoothDevices::~BluetoothDevices()
{
    // a scan that is still ours ends with the page (stock: onPause)
    if (m_weStarted && !m_adapter.isEmpty() && m_bus.isConnected()) {
        QDBusMessage m = QDBusMessage::createMethodCall(m_service, m_adapter, kAdapter, QStringLiteral("StopDiscovery"));
        m_bus.asyncCall(m, 5000);
    }
}

void BluetoothDevices::setConnection(const QDBusConnection &bus, const QString &service)
{
    m_bus = bus;
    m_service = service;
}

void BluetoothDevices::init()
{
    if (m_started)
        return;
    m_started = true;
    if (!m_bus.isConnected())
        return;
    const QString none;
    m_bus.connect(m_service, none, kManager, QStringLiteral("InterfacesAdded"),
                  this, SLOT(onInterfacesAdded(QDBusObjectPath, BtInterfaceList)));
    m_bus.connect(m_service, none, kManager, QStringLiteral("InterfacesRemoved"),
                  this, SLOT(onInterfacesRemoved(QDBusObjectPath, QStringList)));
    m_bus.connect(m_service, none, kProps, QStringLiteral("PropertiesChanged"),
                  this, SLOT(onPropertiesChanged(QString, QVariantMap, QStringList)));
    m_bus.connect(QStringLiteral("org.freedesktop.DBus"), QStringLiteral("/org/freedesktop/DBus"),
                  QStringLiteral("org.freedesktop.DBus"), QStringLiteral("NameOwnerChanged"),
                  this, SLOT(onNameOwnerChanged(QString, QString, QString)));
    QDBusMessage m = QDBusMessage::createMethodCall(m_service, QStringLiteral("/"), kManager, QStringLiteral("GetManagedObjects"));
    auto *w = new QDBusPendingCallWatcher(m_bus.asyncCall(m), this);
    connect(w, &QDBusPendingCallWatcher::finished, this, &BluetoothDevices::onManagedObjects);
}

void BluetoothDevices::onManagedObjects(QDBusPendingCallWatcher *w)
{
    w->deleteLater();
    QDBusPendingReply<BtManagedObjects> reply = *w;
    if (reply.isError())
        return;
    const BtManagedObjects objs = reply.value();
    for (auto it = objs.constBegin(); it != objs.constEnd(); ++it)
        onInterfacesAdded(it.key(), it.value());
}

void BluetoothDevices::onNameOwnerChanged(const QString &name, const QString &, const QString &newOwner)
{
    if (name != m_service || !newOwner.isEmpty())
        return;
    // bluetoothd went away: no adapter, no scan
    clearAdapter();
    m_connecting.clear();
    m_pairing.clear();
    for (auto it = m_devices.begin(); it != m_devices.end(); ++it)
        it->connected = false;
    rebuild();
}

void BluetoothDevices::setAdapter(const QString &path, const QVariantMap &props)
{
    const bool wasAvailable = available();
    m_adapter = path;
    if (props.contains(QStringLiteral("Powered"))) {
        const bool p = props.value(QStringLiteral("Powered")).toBool();
        if (p != m_powered) {
            m_powered = p;
            emit poweredChanged();
        }
    }
    if (props.contains(QStringLiteral("Discovering"))) {
        const bool d = props.value(QStringLiteral("Discovering")).toBool();
        if (d != m_discovering) {
            m_discovering = d;
            emit discoveringChanged();
        }
    }
    if (!wasAvailable)
        emit availableChanged();
}

void BluetoothDevices::clearAdapter()
{
    const bool wasAvailable = available();
    m_adapter.clear();
    m_weStarted = false;
    if (m_powered) {
        m_powered = false;
        emit poweredChanged();
    }
    if (m_discovering) {
        m_discovering = false;
        emit discoveringChanged();
    }
    if (wasAvailable)
        emit availableChanged();
}

void BluetoothDevices::applyDeviceProps(Device &d, const QVariantMap &props, bool fromScan)
{
    if (props.contains(QStringLiteral("Name")))
        d.name = props.value(QStringLiteral("Name")).toString();
    if (props.contains(QStringLiteral("Alias")))
        d.alias = props.value(QStringLiteral("Alias")).toString();
    if (props.contains(QStringLiteral("Address")))
        d.address = props.value(QStringLiteral("Address")).toString();
    if (props.contains(QStringLiteral("Icon")))
        d.icon = props.value(QStringLiteral("Icon")).toString();
    if (props.contains(QStringLiteral("Paired")))
        d.paired = props.value(QStringLiteral("Paired")).toBool();
    if (props.contains(QStringLiteral("Connected")))
        d.connected = props.value(QStringLiteral("Connected")).toBool();
    if (props.contains(QStringLiteral("RSSI"))) {
        d.rssi = props.value(QStringLiteral("RSSI")).toInt();
        d.hasRssi = true;
        // heard now (during a scan, or announced with a signal strength)
        if (m_discovering || fromScan)
            d.seen = true;
    }
}

bool BluetoothDevices::wanted(const Device &d) const
{
    if (m_filter == QLatin1String("paired"))
        return d.paired;
    // available: not paired, and heard during the scan
    return !d.paired && d.seen;
}

QString BluetoothDevices::label(const Device &d) const
{
    // stock BluetoothDevices.friendlyName: the name, else the address
    if (!d.alias.isEmpty())
        return d.alias;
    if (!d.name.isEmpty())
        return d.name;
    return d.address;
}

void BluetoothDevices::onInterfacesAdded(const QDBusObjectPath &opath, const BtInterfaceList &ifaces)
{
    const QString path = opath.path();
    if (ifaces.contains(QLatin1String(kAdapter))) {
        if (m_adapter.isEmpty() || m_adapter == path)
            setAdapter(path, ifaces.value(QLatin1String(kAdapter)));
    }
    if (ifaces.contains(QLatin1String(kDevice))) {
        Device &d = m_devices[path];
        d.path = path;
        // announced while we scan: found now
        applyDeviceProps(d, ifaces.value(QLatin1String(kDevice)), m_discovering);
        if (m_discovering)
            d.seen = true;
        rebuild();
    }
}

void BluetoothDevices::onInterfacesRemoved(const QDBusObjectPath &opath, const QStringList &ifaces)
{
    const QString path = opath.path();
    if (ifaces.contains(QLatin1String(kAdapter)) && path == m_adapter)
        clearAdapter();
    if (ifaces.contains(QLatin1String(kDevice)) && m_devices.contains(path)) {
        m_devices.remove(path);
        m_connecting.remove(path);
        m_pairing.remove(path);
        rebuild();
    }
}

void BluetoothDevices::onPropertiesChanged(const QString &iface, const QVariantMap &changed, const QStringList &)
{
    const QString path = message().path();
    if (iface == QLatin1String(kAdapter)) {
        if (path == m_adapter)
            setAdapter(path, changed);
        return;
    }
    if (iface != QLatin1String(kDevice))
        return;
    auto it = m_devices.find(path);
    if (it == m_devices.end())
        return;
    const bool wasPaired = it->paired;
    applyDeviceProps(*it, changed, false);
    if (changed.contains(QStringLiteral("Connected")) && it->connected)
        m_connecting.remove(path);
    if (changed.contains(QStringLiteral("Paired")) && it->paired) {
        m_pairing.remove(path);
        if (!wasPaired)
            emit paired(path);
    }
    rebuild();
}

void BluetoothDevices::setFilter(const QString &f)
{
    if (f == m_filter)
        return;
    m_filter = f;
    rebuild();
    emit filterChanged();
}

int BluetoothDevices::rowOf(const QString &path) const
{
    return m_rows.indexOf(path);
}

void BluetoothDevices::rebuild()
{
    QVector<QString> next;
    for (auto it = m_devices.constBegin(); it != m_devices.constEnd(); ++it)
        if (wanted(it.value()))
            next.append(it.key());
    if (m_filter == QLatin1String("paired")) {
        std::sort(next.begin(), next.end(), [this](const QString &a, const QString &b) {
            const int c = label(m_devices[a]).compare(label(m_devices[b]), Qt::CaseInsensitive);
            return c != 0 ? c < 0 : a < b;
        });
    } else {
        // in the order they were found: keep what is there, new ones at the end
        QVector<QString> ordered;
        for (const QString &p : std::as_const(m_rows))
            if (next.contains(p))
                ordered.append(p);
        QVector<QString> fresh;
        for (const QString &p : std::as_const(next))
            if (!ordered.contains(p))
                fresh.append(p);
        std::sort(fresh.begin(), fresh.end());
        next = ordered + fresh;
    }
    const int before = m_rows.size();
    if (next != m_rows) {
        // rows that left, from the end
        for (int i = m_rows.size() - 1; i >= 0; --i) {
            if (!next.contains(m_rows[i])) {
                beginRemoveRows(QModelIndex(), i, i);
                m_rows.removeAt(i);
                endRemoveRows();
            }
        }
        // the survivors keep their order? else start over
        QVector<QString> common;
        for (const QString &p : std::as_const(next))
            if (m_rows.contains(p))
                common.append(p);
        if (common != m_rows) {
            beginResetModel();
            m_rows = next;
            endResetModel();
        } else {
            for (int i = 0; i < next.size(); ++i) {
                if (i < m_rows.size() && m_rows[i] == next[i])
                    continue;
                beginInsertRows(QModelIndex(), i, i);
                m_rows.insert(i, next[i]);
                endInsertRows();
            }
        }
    }
    if (m_rows.size() != before)
        emit countChanged();
    if (!m_rows.isEmpty())
        emit dataChanged(index(0), index(m_rows.size() - 1));
    bump();
}

void BluetoothDevices::bump()
{
    m_revision++;
    emit revisionChanged();
}

void BluetoothDevices::updateRow(const QString &path)
{
    const int r = rowOf(path);
    if (r >= 0)
        emit dataChanged(index(r), index(r));
    bump();
}

int BluetoothDevices::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_rows.size();
}

QVariant BluetoothDevices::data(const QModelIndex &idx, int role) const
{
    if (!idx.isValid() || idx.row() < 0 || idx.row() >= m_rows.size())
        return QVariant();
    const QString &path = m_rows.at(idx.row());
    const auto it = m_devices.constFind(path);
    if (it == m_devices.constEnd())
        return QVariant();
    const Device &d = it.value();
    switch (role) {
    case PathRole: return d.path;
    case NameRole: return label(d);
    case AddressRole: return d.address;
    case PairedRole: return d.paired;
    case ConnectedRole: return d.connected;
    case ConnectingRole: return m_connecting.contains(path);
    case PairingRole: return m_pairing.contains(path);
    case IconRole: return d.icon;
    case RssiRole: return d.hasRssi ? QVariant(d.rssi) : QVariant();
    }
    return QVariant();
}

QHash<int, QByteArray> BluetoothDevices::roleNames() const
{
    return {
        { PathRole, "path" },
        { NameRole, "name" },
        { AddressRole, "address" },
        { PairedRole, "paired" },
        { ConnectedRole, "connected" },
        { ConnectingRole, "connecting" },
        { PairingRole, "pairing" },
        { IconRole, "icon" },
        { RssiRole, "rssi" },
    };
}

QVariantMap BluetoothDevices::device(const QString &path) const
{
    QVariantMap out;
    const auto it = m_devices.constFind(path);
    if (it == m_devices.constEnd())
        return out;
    const Device &d = it.value();
    out.insert(QStringLiteral("path"), d.path);
    out.insert(QStringLiteral("name"), label(d));
    out.insert(QStringLiteral("paired"), d.paired);
    out.insert(QStringLiteral("connected"), d.connected);
    out.insert(QStringLiteral("connecting"), m_connecting.contains(path));
    out.insert(QStringLiteral("pairing"), m_pairing.contains(path));
    out.insert(QStringLiteral("icon"), d.icon);
    return out;
}

void BluetoothDevices::startDiscovery()
{
    if (m_adapter.isEmpty() || !m_powered)
        return;
    // heard from now on only
    for (auto it = m_devices.begin(); it != m_devices.end(); ++it)
        it->seen = false;
    rebuild();
    m_weStarted = true;
    QDBusMessage m = QDBusMessage::createMethodCall(m_service, m_adapter, kAdapter, QStringLiteral("StartDiscovery"));
    m_bus.asyncCall(m, 10000);
}

void BluetoothDevices::stopDiscovery()
{
    if (m_adapter.isEmpty() || !m_weStarted)
        return;
    m_weStarted = false;
    QDBusMessage m = QDBusMessage::createMethodCall(m_service, m_adapter, kAdapter, QStringLiteral("StopDiscovery"));
    m_bus.asyncCall(m, 10000);
}

void BluetoothDevices::callDevice(const QString &path, const QString &method, bool pairing)
{
    auto it = m_devices.find(path);
    if (it == m_devices.end())
        return;
    QSet<QString> &busy = pairing ? m_pairing : m_connecting;
    if (busy.contains(path))
        return;
    busy.insert(path);
    updateRow(path);
    QDBusMessage m = QDBusMessage::createMethodCall(m_service, path, kDevice, method);
    auto *w = new QDBusPendingCallWatcher(m_bus.asyncCall(m, pairing ? kPairTimeoutMs : kConnectTimeoutMs), this);
    connect(w, &QDBusPendingCallWatcher::finished, this, [this, path, method, pairing](QDBusPendingCallWatcher *watcher) {
        watcher->deleteLater();
        QSet<QString> &b = pairing ? m_pairing : m_connecting;
        b.remove(path);
        const bool failed = watcher->isError();
        const auto dev = m_devices.constFind(path);
        const QString name = dev == m_devices.constEnd() ? QString() : label(dev.value());
        updateRow(path);
        if (pairing) {
            if (failed) {
                // AlreadyExists: it is paired, carry on
                if (watcher->error().name() != QLatin1String("org.bluez.Error.AlreadyExists")) {
                    emit pairFailed(path, name);
                    return;
                }
            }
            // paired: trust it (BlueZ then reconnects it by itself) and connect, as stock does after a bond
            QDBusMessage t = QDBusMessage::createMethodCall(m_service, path, kProps, QStringLiteral("Set"));
            t << QString::fromLatin1(kDevice) << QStringLiteral("Trusted") << QVariant::fromValue(QDBusVariant(true));
            m_bus.asyncCall(t);
            emit paired(path);
            callDevice(path, QStringLiteral("Connect"), false);
        } else if (failed && method == QLatin1String("Connect")) {
            emit connectFailed(path, name);
        }
    });
}

void BluetoothDevices::pair(const QString &path)
{
    // stock cancels the scan before it bonds
    stopDiscovery();
    callDevice(path, QStringLiteral("Pair"), true);
}

void BluetoothDevices::connectDevice(const QString &path)
{
    callDevice(path, QStringLiteral("Connect"), false);
}

void BluetoothDevices::disconnectDevice(const QString &path)
{
    QDBusMessage m = QDBusMessage::createMethodCall(m_service, path, kDevice, QStringLiteral("Disconnect"));
    m_bus.asyncCall(m, kConnectTimeoutMs);
}

void BluetoothDevices::forget(const QString &path)
{
    if (m_adapter.isEmpty())
        return;
    QDBusMessage m = QDBusMessage::createMethodCall(m_service, m_adapter, kAdapter, QStringLiteral("RemoveDevice"));
    m << QVariant::fromValue(QDBusObjectPath(path));
    m_bus.asyncCall(m, 10000);
}
