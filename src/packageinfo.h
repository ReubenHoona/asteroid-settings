/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef PACKAGEINFO_H
#define PACKAGEINFO_H

#include <QObject>
#include <QString>

/*
 * The version of an installed package (About > Versions > System UI, stock
 * DeviceVersionFragment): read once, when asked, from the package manager's
 * status file (opkg: /var/lib/opkg/status). Nothing is polled.
 *
 *   PackageInfo { id: packages }
 *   packages.version("asteroid-launcher")   // "2.0+git0+1a2b3c-r0", "" if absent
 */
class PackageInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString statusFile READ statusFile WRITE setStatusFile NOTIFY statusFileChanged)
public:
    explicit PackageInfo(QObject *parent = nullptr);

    QString statusFile() const { return m_statusFile; }
    void setStatusFile(const QString &file);

    Q_INVOKABLE QString version(const QString &package) const;
    /* the Installed-Size field in bytes (opkg writes bytes), 0 when unknown */
    Q_INVOKABLE qint64 installedSize(const QString &package) const;

signals:
    void statusFileChanged();

private:
    QString m_statusFile;
};

#endif // PACKAGEINFO_H
