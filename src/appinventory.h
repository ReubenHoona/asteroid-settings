/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef APPINVENTORY_H
#define APPINVENTORY_H

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariantList>

#include "packageinfo.h"

/*
 * What Settings > Apps & notifications > App info and App storage need to
 * know about the apps of the watch (stock: PackageManager and the app's
 * storage stats):
 * - the apps with a launcher entry (desktop files without NoDisplay);
 * - the package an entry came from (the opkg file lists);
 * - whether the app's process runs, and a force stop (SIGKILL of the
 *   processes of this user whose command line names the program);
 * - the sizes of an app: the installed size of its package, its data
 *   (~/.local/share/<name> and ~/.config/<name>) and its cache
 *   (~/.cache/<name>), summed on a pool thread so that the page can say
 *   "Computing..." first (sizesReady);
 * - Clear data and Clear cache: the files in those directories go, the
 *   directories stay.
 * All directories can be set, for the unit test.
 */
class AppInventory : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString desktopDir READ desktopDir WRITE setDesktopDir NOTIFY changed)
    Q_PROPERTY(QString infoDir READ infoDir WRITE setInfoDir NOTIFY changed)
    Q_PROPERTY(QString procDir READ procDir WRITE setProcDir NOTIFY changed)
    Q_PROPERTY(QString homeDir READ homeDir WRITE setHomeDir NOTIFY changed)
    Q_PROPERTY(QString statusFile READ statusFile WRITE setStatusFile NOTIFY changed)
public:
    explicit AppInventory(QObject *parent = nullptr);

    QString desktopDir() const { return m_desktopDir; }
    void setDesktopDir(const QString &dir);
    QString infoDir() const { return m_infoDir; }
    void setInfoDir(const QString &dir);
    QString procDir() const { return m_procDir; }
    void setProcDir(const QString &dir);
    QString homeDir() const { return m_homeDir; }
    void setHomeDir(const QString &dir);
    QString statusFile() const { return m_packages.statusFile(); }
    void setStatusFile(const QString &file);

    /* [{ id, name, exec, process }] sorted by name; process is "" when the
       entry does not run a program of its own (the Assistant entry asks the
       launcher over D-Bus) */
    Q_INVOKABLE QVariantList launcherApps() const;
    /* the opkg package that installed <id>.desktop, "" when unknown */
    Q_INVOKABLE QString packageOf(const QString &desktopId) const;
    Q_INVOKABLE QString version(const QString &package) const { return m_packages.version(package); }
    Q_INVOKABLE bool isRunning(const QString &process) const;
    /* the number of processes killed */
    Q_INVOKABLE int forceStop(const QString &process);
    Q_INVOKABLE void computeSizes(const QString &key, const QStringList &names, const QString &package);
    Q_INVOKABLE bool clearData(const QStringList &names);
    Q_INVOKABLE bool clearCache(const QStringList &names);

    /* the sums, synchronous (what computeSizes runs on the pool) */
    qint64 dataBytes(const QStringList &names) const;
    qint64 cacheBytes(const QStringList &names) const;
    qint64 appBytes(const QString &package) const;

signals:
    void changed();
    void sizesReady(const QString &key, double appBytes, double dataBytes, double cacheBytes);

private:
    QStringList dataDirs(const QStringList &names) const;
    QStringList cacheDirs(const QStringList &names) const;
    QList<qint64> pidsOf(const QString &process) const;
    static qint64 dirBytes(const QString &dir);
    static bool clearDir(const QString &dir);

    QString m_desktopDir;
    QString m_infoDir;
    QString m_procDir;
    QString m_homeDir;
    PackageInfo m_packages;
};

#endif // APPINVENTORY_H
