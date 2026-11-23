/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef PACKAGEINFO_H
#define PACKAGEINFO_H

#include <QObject>
#include <QString>
#include <QVariantList>

/*
 * The version of an installed package (About > Versions > System UI, stock
 * DeviceVersionFragment): read once, when asked, from the package manager's
 * status file (opkg: /var/lib/opkg/status). Nothing is polled.
 *
 *   PackageInfo { id: packages }
 *   packages.version("asteroid-launcher")   // "2.0+git0+1a2b3c-r0", "" if absent
 *
 * The parts System licenses lists (stock SystemLicenseLibrariesFragment),
 * read when asked from the package manager's control files (opkg:
 * /var/lib/opkg/info/<package>.control), in the background as stock reads
 * its list:
 *
 *   PackageInfo { onLicensesRead: (parts) => list.model = parts }
 *   packages.readLicenses()   // parts: [{ name: "qml-asteroid", license: "LGPL-2.1-only", ... }, ...]
 */
class PackageInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString statusFile READ statusFile WRITE setStatusFile NOTIFY statusFileChanged)
    Q_PROPERTY(QString infoDir READ infoDir WRITE setInfoDir NOTIFY infoDirChanged)
public:
    explicit PackageInfo(QObject *parent = nullptr);

    QString statusFile() const { return m_statusFile; }
    void setStatusFile(const QString &file);
    QString infoDir() const { return m_infoDir; }
    void setInfoDir(const QString &dir);

    Q_INVOKABLE QString version(const QString &package) const;
    /* the Installed-Size field in bytes (opkg writes bytes), 0 when unknown */
    Q_INVOKABLE qint64 installedSize(const QString &package) const;
    /*
     * One entry per source recipe of the installed packages, sorted by name
     * as stock sorts its libraries (Collections.sort: by UTF-16 code unit):
     *   { "name": "qml-asteroid", "license": "LGPL-2.1-only",
     *     "packages": ["qml-asteroid"] }
     * The recipe is the OE field of a control file, else its Source without
     * the version and ".bb", else the package. "license" is the License
     * field when all packages of the recipe have the same, else one
     * "package: licence" line per package. Empty when the directory is not
     * there.
     */
    Q_INVOKABLE QVariantList licenses() const;
    /* licenses() on a worker thread (some 750 files on the watch): the
       parts come back with licensesRead() on this object's thread */
    Q_INVOKABLE void readLicenses();

signals:
    void statusFileChanged();
    void infoDirChanged();
    void licensesRead(const QVariantList &parts);

private:
    static QVariantList licensesIn(const QString &infoDir);
    QString m_statusFile;
    QString m_infoDir;
};

#endif // PACKAGEINFO_H
