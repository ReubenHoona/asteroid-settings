/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "packageinfo.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QMap>
#include <QPointer>
#include <QStringList>
#include <QThreadPool>
#include <QVariantMap>

PackageInfo::PackageInfo(QObject *parent)
    : QObject(parent)
    , m_statusFile(QStringLiteral("/var/lib/opkg/status"))
    , m_infoDir(QStringLiteral("/var/lib/opkg/info"))
{
}

void PackageInfo::setInfoDir(const QString &dir)
{
    if (dir == m_infoDir)
        return;
    m_infoDir = dir;
    emit infoDirChanged();
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

namespace {

// the recipe of a package: OE ("qml-asteroid"), else the Source recipe file
// without its version and ".bb" ("qml-asteroid_git.bb"), else the package
QString recipeOf(const QString &oe, const QString &source, const QString &package)
{
    if (!oe.isEmpty())
        return oe;
    QString s = source.section(QLatin1Char(' '), 0, 0).section(QLatin1Char('/'), -1);
    if (s.endsWith(QLatin1String(".bb")))
        s.chop(3);
    const int version = s.indexOf(QLatin1Char('_'));
    if (version >= 0)
        s.truncate(version);
    return s.isEmpty() ? package : s;
}

} // namespace

// a control file is "Field: value" lines; a line that starts with a space
// or a tab goes on with the field before (the description)
QVariantList PackageInfo::licenses() const
{
    return licensesIn(m_infoDir);
}

void PackageInfo::readLicenses()
{
    const QString dir = m_infoDir;
    const QPointer<PackageInfo> self(this);
    QThreadPool::globalInstance()->start([dir, self]() {
        const QVariantList parts = licensesIn(dir);
        // back on the main thread, where the page may have gone meanwhile
        QMetaObject::invokeMethod(QCoreApplication::instance(), [self, parts]() {
            if (self)
                emit self->licensesRead(parts);
        }, Qt::QueuedConnection);
    });
}

// only QDir, QFile and values: safe on a worker thread
QVariantList PackageInfo::licensesIn(const QString &infoDir)
{
    const QDir dir(infoDir);
    const QStringList files = dir.entryList({QStringLiteral("*.control")}, QDir::Files, QDir::Name);
    // recipe -> package -> licence, both sorted (QString's < is Java's
    // String.compareTo)
    QMap<QString, QMap<QString, QString>> parts;
    for (const QString &name : files) {
        QFile file(dir.filePath(name));
        if (!file.open(QIODevice::ReadOnly))
            continue;
        QString package, license, oe, source;
        while (!file.atEnd()) {
            const QByteArray line = file.readLine();
            if (line.isEmpty() || line.at(0) == ' ' || line.at(0) == '\t')
                continue;
            const int colon = line.indexOf(':');
            if (colon <= 0)
                continue;
            const QByteArray field = line.left(colon);
            // one space between words (a licence can have runs of them)
            const QString value = QString::fromUtf8(line.mid(colon + 1)).simplified();
            if (field == "Package")
                package = value;
            else if (field == "License")
                license = value;
            else if (field == "OE")
                oe = value;
            else if (field == "Source")
                source = value;
        }
        if (!package.isEmpty())
            parts[recipeOf(oe, source, package)].insert(package, license);
    }
    QVariantList out;
    for (auto it = parts.cbegin(); it != parts.cend(); ++it) {
        QStringList distinct = it->values();
        distinct.removeDuplicates();
        QString text;
        if (distinct.size() == 1) {
            text = distinct.first();
        } else {
            QStringList lines;
            for (auto p = it->cbegin(); p != it->cend(); ++p)
                lines << p.key() + QLatin1String(": ") + p.value();
            text = lines.join(QLatin1Char('\n'));
        }
        out << QVariantMap{{QStringLiteral("name"), it.key()},
                           {QStringLiteral("license"), text},
                           {QStringLiteral("packages"), QStringList(it->keys())}};
    }
    return out;
}
