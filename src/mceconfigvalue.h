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

#ifndef MCECONFIGVALUE_H
#define MCECONFIGVALUE_H

#include <QObject>
#include <QVariant>
#include <QDBusPendingCallWatcher>

class ComNokiaMceRequestInterface;
class ComNokiaMceSignalInterface;
class QDBusVariant;

/*
 * One mce setting (get_config / set_config / config_change_ind on the
 * system bus), e.g. /system/osso/dsm/display/display_dim_timeout. A value
 * set from QML keeps the type mce has for the key (a JS number becomes an
 * int for an int setting), so mce takes it.
 */
class MceConfigValue : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString key READ key WRITE setKey NOTIFY keyChanged)
    Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY validChanged)

public:
    MceConfigValue(QObject *parent = nullptr);

    QString key() const { return m_key; }
    void setKey(const QString &key);
    QVariant value() const { return m_value; }
    void setValue(const QVariant &value);
    bool valid() const { return m_valid; }

signals:
    void keyChanged();
    void valueChanged();
    void validChanged();

private slots:
    void configChange(const QString &key, const QDBusVariant &value);
    void configReply(QDBusPendingCallWatcher *watcher);

private:
    void update(const QVariant &value);

    ComNokiaMceRequestInterface *m_mceIface;
    ComNokiaMceSignalInterface *m_mceSignalIface;
    QString m_key;
    QVariant m_value;
    int m_type;
    bool m_valid;
};

#endif // MCECONFIGVALUE_H
