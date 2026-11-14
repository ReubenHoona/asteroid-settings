/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "appinventory.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QLocale>
#include <QSettings>
#include <QThreadPool>
#include <algorithm>
#include <signal.h>
#include <sys/types.h>

AppInventory::AppInventory(QObject *parent)
    : QObject(parent)
    , m_desktopDir(QStringLiteral("/usr/share/applications"))
    , m_infoDir(QStringLiteral("/var/lib/opkg/info"))
    , m_procDir(QStringLiteral("/proc"))
    , m_homeDir(QDir::homePath())
{
}

void AppInventory::setDesktopDir(const QString &dir) { if (dir != m_desktopDir) { m_desktopDir = dir; emit changed(); } }
void AppInventory::setInfoDir(const QString &dir) { if (dir != m_infoDir) { m_infoDir = dir; emit changed(); } }
void AppInventory::setProcDir(const QString &dir) { if (dir != m_procDir) { m_procDir = dir; emit changed(); } }
void AppInventory::setHomeDir(const QString &dir) { if (dir != m_homeDir) { m_homeDir = dir; emit changed(); } }
void AppInventory::setStatusFile(const QString &file)
{
    if (file != m_packages.statusFile()) {
        m_packages.setStatusFile(file);
        emit changed();
    }
}

// a desktop entry's own name in the language of the user, else Name
static QString entryName(QSettings &entry)
{
    const QLocale locale;
    const QString full = locale.name();
    const QString lang = full.section(QLatin1Char('_'), 0, 0);
    const QStringList keys = { QStringLiteral("Name[") + full + QLatin1Char(']'),
                               QStringLiteral("Name[") + lang + QLatin1Char(']') };
    for (const QString &key : keys) {
        const QString value = entry.value(key).toStringList().join(QLatin1Char(','));
        if (!value.isEmpty())
            return value;
    }
    return entry.value(QStringLiteral("Name")).toStringList().join(QLatin1Char(','));
}

QVariantList AppInventory::launcherApps() const
{
    static const QStringList launchers = { QStringLiteral("busctl"), QStringLiteral("env"), QStringLiteral("sh"),
                                           QStringLiteral("invoker"), QStringLiteral("dbus-send"),
                                           QStringLiteral("systemctl") };
    QVariantList out;
    const QDir dir(m_desktopDir);
    const QStringList files = dir.entryList({ QStringLiteral("*.desktop") }, QDir::Files, QDir::Name);
    for (const QString &file : files) {
        QSettings entry(dir.filePath(file), QSettings::IniFormat);
        entry.beginGroup(QStringLiteral("Desktop Entry"));
        const QString type = entry.value(QStringLiteral("Type")).toString();
        if ((!type.isEmpty() && type != QLatin1String("Application"))
            || entry.value(QStringLiteral("NoDisplay")).toString() == QLatin1String("true")
            || entry.value(QStringLiteral("Hidden")).toString() == QLatin1String("true"))
            continue;
        const QString exec = entry.value(QStringLiteral("Exec")).toStringList().join(QLatin1Char(','));
        QString process = QFileInfo(exec.section(QLatin1Char(' '), 0, 0)).fileName();
        if (launchers.contains(process))
            process.clear();
        QVariantMap app;
        app.insert(QStringLiteral("id"), QFileInfo(file).completeBaseName());
        app.insert(QStringLiteral("name"), entryName(entry));
        app.insert(QStringLiteral("exec"), exec);
        app.insert(QStringLiteral("process"), process);
        out.append(app);
    }
    std::sort(out.begin(), out.end(), [](const QVariant &a, const QVariant &b) {
        return QString::localeAwareCompare(a.toMap().value(QStringLiteral("name")).toString(),
                                           b.toMap().value(QStringLiteral("name")).toString()) < 0;
    });
    return out;
}

QString AppInventory::packageOf(const QString &desktopId) const
{
    if (desktopId.isEmpty() || desktopId.contains(QLatin1Char('/')))
        return QString();
    const QByteArray suffix = "/applications/" + desktopId.toUtf8() + ".desktop";
    const QDir dir(m_infoDir);
    const QStringList lists = dir.entryList({ QStringLiteral("*.list") }, QDir::Files, QDir::Name);
    for (const QString &list : lists) {
        QFile file(dir.filePath(list));
        if (!file.open(QIODevice::ReadOnly))
            continue;
        while (!file.atEnd()) {
            if (file.readLine().trimmed().endsWith(suffix))
                return list.left(list.size() - 5);
        }
    }
    return QString();
}

QList<qint64> AppInventory::pidsOf(const QString &process) const
{
    QList<qint64> pids;
    if (process.isEmpty())
        return pids;
    const qint64 self = QCoreApplication::applicationPid();
    const QDir proc(m_procDir);
    const QStringList entries = proc.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &entry : entries) {
        bool ok = false;
        const qint64 pid = entry.toLongLong(&ok);
        if (!ok || pid == self)
            continue;
        QFile file(proc.filePath(entry + QStringLiteral("/cmdline")));
        if (!file.open(QIODevice::ReadOnly))
            continue;
        const QList<QByteArray> args = file.readAll().split('\0');
        for (const QByteArray &arg : args) {
            if (!arg.isEmpty() && QFileInfo(QString::fromUtf8(arg)).fileName() == process) {
                pids.append(pid);
                break;
            }
        }
    }
    return pids;
}

bool AppInventory::isRunning(const QString &process) const
{
    return !pidsOf(process).isEmpty();
}

int AppInventory::forceStop(const QString &process)
{
    int killed = 0;
    for (qint64 pid : pidsOf(process)) {
        if (::kill(static_cast<pid_t>(pid), SIGKILL) == 0)
            killed++;
    }
    return killed;
}

static bool plainName(const QString &name)
{
    return !name.isEmpty() && !name.contains(QLatin1Char('/')) && !name.startsWith(QLatin1Char('.'));
}

QStringList AppInventory::dataDirs(const QStringList &names) const
{
    QStringList dirs;
    for (const QString &n : names) {
        if (!plainName(n))
            continue;
        dirs << m_homeDir + QStringLiteral("/.local/share/") + n << m_homeDir + QStringLiteral("/.config/") + n;
    }
    return dirs;
}

QStringList AppInventory::cacheDirs(const QStringList &names) const
{
    QStringList dirs;
    for (const QString &n : names) {
        if (plainName(n))
            dirs << m_homeDir + QStringLiteral("/.cache/") + n;
    }
    return dirs;
}

qint64 AppInventory::dirBytes(const QString &dir)
{
    qint64 total = 0;
    QDirIterator it(dir, QDir::Files | QDir::Hidden | QDir::NoSymLinks, QDirIterator::Subdirectories);
    while (it.hasNext()) {
        it.next();
        total += it.fileInfo().size();
    }
    return total;
}

qint64 AppInventory::dataBytes(const QStringList &names) const
{
    qint64 total = 0;
    for (const QString &d : dataDirs(names))
        total += dirBytes(d);
    return total;
}

qint64 AppInventory::cacheBytes(const QStringList &names) const
{
    qint64 total = 0;
    for (const QString &d : cacheDirs(names))
        total += dirBytes(d);
    return total;
}

qint64 AppInventory::appBytes(const QString &package) const
{
    return m_packages.installedSize(package);
}

void AppInventory::computeSizes(const QString &key, const QStringList &names, const QString &package)
{
    QThreadPool::globalInstance()->start([this, key, names, package]() {
        const double app = double(appBytes(package));
        const double data = double(dataBytes(names));
        const double cache = double(cacheBytes(names));
        QMetaObject::invokeMethod(this, [this, key, app, data, cache]() { emit sizesReady(key, app, data, cache); },
                                  Qt::QueuedConnection);
    });
}

// everything under the directory goes, the directory itself stays
bool AppInventory::clearDir(const QString &dir)
{
    const QDir d(dir);
    if (!d.exists())
        return true;
    bool ok = true;
    const QFileInfoList entries = d.entryInfoList(QDir::AllEntries | QDir::Hidden | QDir::NoDotAndDotDot | QDir::System);
    for (const QFileInfo &e : entries) {
        if (e.isDir() && !e.isSymLink())
            ok = QDir(e.absoluteFilePath()).removeRecursively() && ok;
        else
            ok = QFile::remove(e.absoluteFilePath()) && ok;
    }
    return ok;
}

bool AppInventory::clearData(const QStringList &names)
{
    bool ok = true;
    for (const QString &d : dataDirs(names))
        ok = clearDir(d) && ok;
    return ok;
}

bool AppInventory::clearCache(const QStringList &names)
{
    bool ok = true;
    for (const QString &d : cacheDirs(names))
        ok = clearDir(d) && ok;
    return ok;
}
