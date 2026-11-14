/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef BLUETOOTHDEVICES_H
#define BLUETOOTHDEVICES_H

#include <QAbstractListModel>
#include <QDBusConnection>
#include <QDBusContext>
#include <QDBusObjectPath>
#include <QHash>
#include <QSet>
#include <QString>
#include <QStringList>
#include <QVariantMap>
#include <QVector>

typedef QMap<QString, QVariantMap> BtInterfaceList;
typedef QMap<QDBusObjectPath, BtInterfaceList> BtManagedObjects;

/*
 * The Bluetooth devices of BlueZ for Settings > Connectivity > Bluetooth
 * (stock BluetoothSettingsFragmentBase, BluetoothScanFragment and
 * BluetoothDevicePreference), one object per page:
 *   filter "paired":    the paired devices (page "Devices" category);
 *   filter "available": the devices the scan found, not paired (Pair new
 *                       device). A device counts as found when BlueZ
 *                       announces it or its signal strength changes while
 *                       the scan runs, so devices cached from earlier scans
 *                       do not show until they are heard again.
 * A row says what stock's summary says: connected, connecting (a Connect in
 * flight), pairing (a Pair in flight).
 *
 * Power: no timer and no polling. The object tree is read once, then the
 * model follows BlueZ's signals (InterfacesAdded/Removed, PropertiesChanged)
 * for as long as the page lives. Discovery runs only between startDiscovery()
 * and stopDiscovery() (the scan page, as stock: it stops when the page
 * pauses) and is stopped in the destructor if it is still ours. Pairing
 * dialogs are the launcher's agent: this class only calls Device1.Pair().
 * The bus can be set, for the unit test.
 */
class BluetoothDevices : public QAbstractListModel, protected QDBusContext
{
    Q_OBJECT
    Q_PROPERTY(QString filter READ filter WRITE setFilter NOTIFY filterChanged)
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(bool powered READ powered NOTIFY poweredChanged)
    Q_PROPERTY(bool discovering READ discovering NOTIFY discoveringChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    // counts up whenever anything about a device changes: a page that shows one
    // device (device(path)) binds to it
    Q_PROPERTY(int revision READ revision NOTIFY revisionChanged)

public:
    enum Roles {
        PathRole = Qt::UserRole + 1,
        NameRole,
        AddressRole,
        PairedRole,
        ConnectedRole,
        ConnectingRole,
        PairingRole,
        IconRole,
        RssiRole
    };
    Q_ENUM(Roles)

    explicit BluetoothDevices(QObject *parent = nullptr);
    ~BluetoothDevices() override;

    // the bus and BlueZ's service name (before the event loop runs)
    void setConnection(const QDBusConnection &bus, const QString &service = QStringLiteral("org.bluez"));

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    QString filter() const { return m_filter; }
    void setFilter(const QString &f);
    bool available() const { return !m_adapter.isEmpty(); }
    bool powered() const { return m_powered; }
    bool discovering() const { return m_discovering; }
    int count() const { return m_rows.size(); }
    int revision() const { return m_revision; }

    Q_INVOKABLE void startDiscovery();
    Q_INVOKABLE void stopDiscovery();
    Q_INVOKABLE void pair(const QString &path);
    Q_INVOKABLE void connectDevice(const QString &path);
    Q_INVOKABLE void disconnectDevice(const QString &path);
    Q_INVOKABLE void forget(const QString &path);
    // the row for a path as a map (name, paired, connected, ...), empty if gone
    Q_INVOKABLE QVariantMap device(const QString &path) const;

signals:
    void filterChanged();
    void availableChanged();
    void poweredChanged();
    void discoveringChanged();
    void countChanged();
    void revisionChanged();
    // Pair() failed or was refused: stock's "Couldn't connect with %1"
    void pairFailed(const QString &path, const QString &name);
    // Connect() on a paired device failed
    void connectFailed(const QString &path, const QString &name);
    // a pairing finished and the device is paired now
    void paired(const QString &path);

private slots:
    void init();
    void onManagedObjects(class QDBusPendingCallWatcher *w);
    void onInterfacesAdded(const QDBusObjectPath &path, const BtInterfaceList &ifaces);
    void onInterfacesRemoved(const QDBusObjectPath &path, const QStringList &ifaces);
    void onPropertiesChanged(const QString &iface, const QVariantMap &changed, const QStringList &invalidated);
    void onNameOwnerChanged(const QString &name, const QString &oldOwner, const QString &newOwner);

private:
    struct Device {
        QString path;
        QString name;
        QString alias;
        QString address;
        QString icon;
        bool paired = false;
        bool connected = false;
        bool seen = false;       // heard during this scan
        int rssi = 0;
        bool hasRssi = false;
    };
    bool wanted(const Device &d) const;
    void applyDeviceProps(Device &d, const QVariantMap &props, bool fromScan);
    void rebuild();
    void bump();
    void updateRow(const QString &path);
    void setAdapter(const QString &path, const QVariantMap &props);
    void clearAdapter();
    void callDevice(const QString &path, const QString &method, bool pairing);
    QString label(const Device &d) const;
    int rowOf(const QString &path) const;

    QDBusConnection m_bus;
    QString m_service;
    QString m_filter = QStringLiteral("paired");
    QString m_adapter;
    bool m_powered = false;
    bool m_discovering = false;
    bool m_weStarted = false;
    bool m_started = false;
    int m_revision = 0;
    QHash<QString, Device> m_devices;
    QVector<QString> m_rows;     // paths shown, in order
    QSet<QString> m_connecting;
    QSet<QString> m_pairing;
};

#endif // BLUETOOTHDEVICES_H
