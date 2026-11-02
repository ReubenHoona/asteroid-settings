/*
 * Copyright (C) 2026 Reuben Horner <reubarb.scons@gmail.com>
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

#include "mceconfigvalue.h"
#include <QDBusConnection>
#include <QDBusObjectPath>
#include <QDBusVariant>
#include <QtMath>

#include <mce/dbus-names.h>
#include "mceinterface.h"

MceConfigValue::MceConfigValue(QObject *parent) :
    QObject(parent),
    m_type(QMetaType::UnknownType),
    m_valid(false)
{
    m_mceSignalIface = new ComNokiaMceSignalInterface(MCE_SERVICE, MCE_SIGNAL_PATH, QDBusConnection::systemBus(), this);
    connect(m_mceSignalIface, SIGNAL(config_change_ind(QString,QDBusVariant)), this, SLOT(configChange(QString,QDBusVariant)));
    m_mceIface = new ComNokiaMceRequestInterface(MCE_SERVICE, MCE_REQUEST_PATH, QDBusConnection::systemBus(), this);
}

void MceConfigValue::setKey(const QString &key)
{
    if (key == m_key)
        return;
    m_key = key;
    emit keyChanged();
    if (m_valid) {
        m_valid = false;
        emit validChanged();
    }
    if (m_key.isEmpty())
        return;
    QDBusPendingReply<QDBusVariant> call = m_mceIface->get_config(QDBusObjectPath(m_key));
    QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(call, this);
    watcher->setProperty("key", m_key);
    connect(watcher, SIGNAL(finished(QDBusPendingCallWatcher *)), this, SLOT(configReply(QDBusPendingCallWatcher *)));
}

void MceConfigValue::configReply(QDBusPendingCallWatcher *watcher)
{
    QDBusPendingReply<QDBusVariant> reply = *watcher;
    if (reply.isError())
        qWarning("mce: could not read %s: %s", qPrintable(watcher->property("key").toString()),
                 qPrintable(reply.error().message()));
    else if (watcher->property("key").toString() == m_key)
        update(reply.value().variant());
    watcher->deleteLater();
}

void MceConfigValue::configChange(const QString &key, const QDBusVariant &value)
{
    if (key == m_key)
        update(value.variant());
}

void MceConfigValue::update(const QVariant &value)
{
    m_type = value.typeId();
    if (!m_valid) {
        m_valid = true;
        emit validChanged();
    }
    if (value != m_value) {
        m_value = value;
        emit valueChanged();
    }
}

void MceConfigValue::setValue(const QVariant &value)
{
    if (m_key.isEmpty())
        return;
    QVariant v = value;
    // mce checks the type: a JS number is a double, an int setting wants an int
    if (m_type != QMetaType::UnknownType && v.typeId() != m_type) {
        if (m_type == QMetaType::Int && v.canConvert<double>())
            v = QVariant(int(qRound(v.toDouble())));
        else
            v.convert(QMetaType(m_type));
    } else if (m_type == QMetaType::UnknownType && v.typeId() == QMetaType::Double
               && v.toDouble() == qFloor(v.toDouble())) {
        v = QVariant(int(v.toDouble()));
    }
    m_mceIface->set_config(QDBusObjectPath(m_key), QDBusVariant(v));
    if (v != m_value) {
        m_value = v;
        emit valueChanged();
    }
}
