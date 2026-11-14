/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#ifndef TIMEZONEMODEL_H
#define TIMEZONEMODEL_H

#include <QDateTime>
#include <QObject>
#include <QStringList>
#include <QVector>

/*
 * The time zones of Settings > Date & time > Set time zone as stock lists
 * them (settingslib ZoneGetter, ManualTimeZonePreference:145-175,
 * TimeZoneDataSource): one flat list sorted by the offset from UTC, then by
 * the city, each zone as its city and "GMT+13:00". The zones are the canonical
 * ones of the tz database's zone.tab (one per country region), with the offset
 * of the moment given to reload(). Nothing runs until QML calls reload() or
 * labelFor(); the model is not updated afterwards (no timers).
 *
 *   TimeZoneModel { id: zones }
 *   zones.reload(); zones.city(i); zones.offsetText(i); zones.zoneId(i)
 *   zones.labelFor("Pacific/Auckland")   // "GMT+13:00 NZDT"
 */
class TimeZoneModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString tabFile READ tabFile WRITE setTabFile NOTIFY tabFileChanged)
public:
    struct Zone {
        QString id;
        QString city;
        int offset;
        QString abbreviation;
    };

    explicit TimeZoneModel(QObject *parent = nullptr);

    int count() const { return m_zones.size(); }
    QString tabFile() const { return m_tabFile; }
    void setTabFile(const QString &file);

    // builds the list at \a at (the current time when invalid)
    Q_INVOKABLE void reload(const QDateTime &at = QDateTime());
    Q_INVOKABLE QString zoneId(int row) const;
    Q_INVOKABLE QString city(int row) const;
    Q_INVOKABLE QString offsetText(int row) const;
    Q_INVOKABLE QString abbreviation(int row) const;
    Q_INVOKABLE int offsetSeconds(int row) const;
    // the row of a zone id, -1 when it is not in the list
    Q_INVOKABLE int indexOf(const QString &zoneId) const;
    // "GMT+13:00" (seconds east of UTC; "GMT+00:00" at 0, "GMT-03:30")
    Q_INVOKABLE static QString offsetLabel(int seconds);
    // "Auckland": the last part of a zone id, underscores as spaces
    Q_INVOKABLE static QString cityOf(const QString &zoneId);
    // "GMT+13:00 NZDT": the offset and the zone's short name, which is left
    // out when it is GMT-like ("UTC", "GMT", "+03"); \a at as for reload()
    Q_INVOKABLE QString labelFor(const QString &zoneId, const QDateTime &at = QDateTime()) const;

signals:
    void countChanged();
    void tabFileChanged();

private:
    static QString shortName(const QString &abbreviation);

    QString m_tabFile;
    QVector<Zone> m_zones;
};

#endif // TIMEZONEMODEL_H
