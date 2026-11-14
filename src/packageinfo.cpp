/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "packageinfo.h"

#include <QFile>

PackageInfo::PackageInfo(QObject *parent)
    : QObject(parent)
    , m_statusFile(QStringLiteral("/var/lib/opkg/status"))
{
}

void PackageInfo::setStatusFile(const QString &file)
{
    if (file == m_statusFile)
        return;
    m_statusFile = file;
    emit statusFileChanged();
}

// the status file is blocks of "Field: value" lines separated by a blank line
QString PackageInfo::version(const QString &package) const
{
    QFile file(m_statusFile);
    if (package.isEmpty() || !file.open(QIODevice::ReadOnly))
        return QString();
    const QByteArray wanted = package.toUtf8();
    bool inPackage = false;
    while (!file.atEnd()) {
        const QByteArray line = file.readLine().trimmed();
        if (line.isEmpty()) {
            inPackage = false;
        } else if (line.startsWith("Package:")) {
            inPackage = line.mid(8).trimmed() == wanted;
        } else if (inPackage && line.startsWith("Version:")) {
            return QString::fromUtf8(line.mid(8).trimmed());
        }
    }
    return QString();
}

qint64 PackageInfo::installedSize(const QString &package) const
{
    QFile file(m_statusFile);
    if (package.isEmpty() || !file.open(QIODevice::ReadOnly))
        return 0;
    const QByteArray wanted = package.toUtf8();
    bool inPackage = false;
    while (!file.atEnd()) {
        const QByteArray line = file.readLine().trimmed();
        if (line.isEmpty()) {
            inPackage = false;
        } else if (line.startsWith("Package:")) {
            inPackage = line.mid(8).trimmed() == wanted;
        } else if (inPackage && line.startsWith("Installed-Size:")) {
            return line.mid(15).trimmed().toLongLong();
        }
    }
    return 0;
}
