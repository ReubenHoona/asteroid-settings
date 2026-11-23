/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 *
 * PackageInfo::licenses() (About > System licenses) on the control files in
 * info/ beside this file: one entry per source recipe, sorted as stock sorts
 * its libraries (Java's Collections.sort), the licence whole or one line per
 * package. Not part of the app build: moc this file and src/packageinfo.h,
 * build it with src/packageinfo.cpp against Qt 6 Core and Test, run it in
 * this directory. EOS_OPKG_INFO=<rootfs>/var/lib/opkg/info also checks an
 * image's own control files.
 */

#include <QtTest>

#include "packageinfo.h"

class TstPackageInfo : public QObject
{
    Q_OBJECT

    static QString entry(const QVariantList &parts, const QString &name, const char *field)
    {
        for (const QVariant &v : parts) {
            const QVariantMap m = v.toMap();
            if (m.value(QStringLiteral("name")).toString() == name) {
                const QVariant value = m.value(QLatin1String(field));
                return value.typeId() == QMetaType::QStringList ? value.toStringList().join(QLatin1Char(','))
                                                                : value.toString();
            }
        }
        return QStringLiteral("<none>");
    }

private slots:
    void infoDir()
    {
        PackageInfo p;
        QCOMPARE(p.infoDir(), QStringLiteral("/var/lib/opkg/info"));
        QSignalSpy spy(&p, &PackageInfo::infoDirChanged);
        p.setInfoDir(QStringLiteral("/tmp"));
        p.setInfoDir(QStringLiteral("/tmp"));
        QCOMPARE(spy.count(), 1);
        QCOMPARE(p.infoDir(), QStringLiteral("/tmp"));
    }

    void fixture()
    {
        PackageInfo p;
        const QString dir = QFINDTESTDATA("info");
        QVERIFY(!dir.isEmpty());
        p.setInfoDir(dir);
        const QVariantList parts = p.licenses();
        QStringList names;
        for (const QVariant &v : parts)
            names << v.toMap().value(QStringLiteral("name")).toString();
        // by UTF-16 code unit, as String.compareTo; README, bar.list and a
        // control file with no Package line are not parts
        QCOMPARE(names, QStringList({QStringLiteral("Zeta"), QStringLiteral("bar"), QStringLiteral("foo"),
                                     QStringLiteral("qml-asteroid"), QStringLiteral("qtbase")}));
        // the License field, not a description line that looks like one
        QCOMPARE(entry(parts, QStringLiteral("qml-asteroid"), "license"), QStringLiteral("LGPL-2.1-only"));
        QCOMPARE(entry(parts, QStringLiteral("qml-asteroid"), "packages"), QStringLiteral("qml-asteroid"));
        // packages of one recipe with different licences: one line each,
        // by package name
        QCOMPARE(entry(parts, QStringLiteral("foo"), "license"),
                 QStringLiteral("foo-tools: GPL-2.0-only\nlibfoo1: MIT"));
        QCOMPARE(entry(parts, QStringLiteral("foo"), "packages"), QStringLiteral("foo-tools,libfoo1"));
        // the same licence (once its runs of spaces are one) is shown once
        QCOMPARE(entry(parts, QStringLiteral("qtbase"), "license"),
                 QStringLiteral("(MIT | BSD-3-Clause) & Apache-2.0"));
        QCOMPARE(entry(parts, QStringLiteral("qtbase"), "packages"), QStringLiteral("qtbase,qtbase-plugins"));
        // no OE field: the Source recipe without its directory and version
        QCOMPARE(entry(parts, QStringLiteral("Zeta"), "license"), QStringLiteral("BSD-3-Clause"));
        // neither: the package itself
        QCOMPARE(entry(parts, QStringLiteral("bar"), "license"), QStringLiteral("Apache-2.0"));
        QCOMPARE(entry(parts, QStringLiteral("nameless"), "license"), QStringLiteral("<none>"));
    }

    // in the background: the same parts, back on the test's thread
    void readLicenses()
    {
        PackageInfo p;
        p.setInfoDir(QFINDTESTDATA("info"));
        QSignalSpy spy(&p, &PackageInfo::licensesRead);
        p.readLicenses();
        QCOMPARE(spy.count(), 0);
        QVERIFY(spy.wait(5000));
        QCOMPARE(spy.count(), 1);
        QCOMPARE(spy.at(0).at(0).toList(), p.licenses());
        // a PackageInfo that is gone by then gets nothing (and nothing crashes)
        auto *gone = new PackageInfo;
        gone->setInfoDir(QFINDTESTDATA("info"));
        gone->readLicenses();
        delete gone;
        QTest::qWait(200);
    }

    void missingDir()
    {
        PackageInfo p;
        p.setInfoDir(QStringLiteral("/nonexistent/opkg/info"));
        QVERIFY(p.licenses().isEmpty());
    }

    void image()
    {
        const QString dir = qEnvironmentVariable("EOS_OPKG_INFO");
        if (dir.isEmpty())
            QSKIP("EOS_OPKG_INFO is not set");
        PackageInfo p;
        p.setInfoDir(dir);
        QElapsedTimer timer;
        timer.start();
        const QVariantList parts = p.licenses();
        const qint64 ms = timer.elapsed();
        int packages = 0;
        QString before;
        for (const QVariant &v : parts) {
            const QVariantMap m = v.toMap();
            const QString name = m.value(QStringLiteral("name")).toString();
            QVERIFY2(before.isEmpty() || before < name, qPrintable(before + QLatin1String(" before ") + name));
            QVERIFY2(!m.value(QStringLiteral("license")).toString().isEmpty(), qPrintable(name));
            before = name;
            packages += m.value(QStringLiteral("packages")).toStringList().size();
        }
        qInfo("%lld parts of %d packages in %lld ms", qint64(parts.size()), packages, ms);
        QCOMPARE(packages, int(QDir(dir).entryList({QStringLiteral("*.control")}, QDir::Files).size()));
        QCOMPARE(entry(parts, QStringLiteral("asteroid-settings"), "license"), QStringLiteral("GPL-3.0-only"));
        QCOMPARE(entry(parts, QStringLiteral("qml-asteroid"), "license"), QStringLiteral("LGPL-2.1-only"));
        QCOMPARE(entry(parts, QStringLiteral("eos-kernel-boot"), "license"), QStringLiteral("GPL-2.0-only"));
    }
};

QTEST_GUILESS_MAIN(TstPackageInfo)
#include "tst_packageinfo.moc"
