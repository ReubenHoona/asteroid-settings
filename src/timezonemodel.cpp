/*
 * Copyright (C) 2026 eos-mainline contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "timezonemodel.h"

#include <QCollator>
#include <QFile>
#include <QLocale>
#include <QTimeZone>
#include <algorithm>

TimeZoneModel::TimeZoneModel(QObject *parent)
    : QObject(parent)
    , m_tabFile(QStringLiteral("/usr/share/zoneinfo/zone.tab"))
{
}

void TimeZoneModel::setTabFile(const QString &file)
{
    if (file == m_tabFile)
        return;
    m_tabFile = file;
    emit tabFileChanged();
}

QString TimeZoneModel::cityOf(const QString &zoneId)
{
    QString city = zoneId.section(QLatin1Char('/'), -1);
    city.replace(QLatin1Char('_'), QLatin1Char(' '));
    return city;
}

QString TimeZoneModel::offsetLabel(int seconds)
{
    const int minutes = qAbs(seconds) / 60;
    return QStringLiteral("GMT%1%2:%3")
        .arg(seconds < 0 ? QLatin1Char('-') : QLatin1Char('+'))
        .arg(minutes / 60, 2, 10, QLatin1Char('0'))
        .arg(minutes % 60, 2, 10, QLatin1Char('0'));
}

// stock shows the short name only when it is not GMT-like
QString TimeZoneModel::shortName(const QString &abbreviation)
{
    if (abbreviation.isEmpty() || abbreviation.startsWith(QLatin1String("GMT"))
        || abbreviation.startsWith(QLatin1String("UTC"))
        || abbreviation.startsWith(QLatin1Char('+')) || abbreviation.startsWith(QLatin1Char('-')))
        return QString();
    return abbreviation;
}

void TimeZoneModel::reload(const QDateTime &at)
{
    const QDateTime when = at.isValid() ? at : QDateTime::currentDateTimeUtc();
    QVector<Zone> zones;
    QFile file(m_tabFile);
    if (file.open(QIODevice::ReadOnly)) {
        const QList<QByteArray> lines = file.readAll().split('\n');
        for (const QByteArray &raw : lines) {
            if (raw.isEmpty() || raw.startsWith('#'))
                continue;
            // country code, coordinates, zone id, comments (tab separated)
            const QList<QByteArray> fields = raw.split('\t');
            if (fields.size() < 3)
                continue;
            const QString id = QString::fromLatin1(fields.at(2)).trimmed();
            const QTimeZone zone(id.toLatin1());
            if (!zone.isValid())
                continue;
            zones.append({ id, cityOf(id), zone.offsetFromUtc(when), shortName(zone.abbreviation(when)) });
        }
    }
    const QCollator collator;
    std::sort(zones.begin(), zones.end(), [&collator](const Zone &a, const Zone &b) {
        if (a.offset != b.offset)
            return a.offset < b.offset;
        const int c = collator.compare(a.city, b.city);
        return c != 0 ? c < 0 : a.id < b.id;
    });
    const bool changed = zones.size() != m_zones.size();
    m_zones = zones;
    if (changed)
        emit countChanged();
}

QString TimeZoneModel::zoneId(int row) const
{
    return row >= 0 && row < m_zones.size() ? m_zones.at(row).id : QString();
}

QString TimeZoneModel::city(int row) const
{
    return row >= 0 && row < m_zones.size() ? m_zones.at(row).city : QString();
}

QString TimeZoneModel::offsetText(int row) const
{
    return row >= 0 && row < m_zones.size() ? offsetLabel(m_zones.at(row).offset) : QString();
}

QString TimeZoneModel::abbreviation(int row) const
{
    return row >= 0 && row < m_zones.size() ? m_zones.at(row).abbreviation : QString();
}

int TimeZoneModel::offsetSeconds(int row) const
{
    return row >= 0 && row < m_zones.size() ? m_zones.at(row).offset : 0;
}

int TimeZoneModel::indexOf(const QString &zoneId) const
{
    for (int i = 0; i < m_zones.size(); i++)
        if (m_zones.at(i).id == zoneId)
            return i;
    return -1;
}

QString TimeZoneModel::labelFor(const QString &zoneId, const QDateTime &at) const
{
    const QTimeZone zone(zoneId.toLatin1());
    if (zoneId.isEmpty() || !zone.isValid())
        return QString();
    const QDateTime when = at.isValid() ? at : QDateTime::currentDateTimeUtc();
    const QString name = shortName(zone.abbreviation(when));
    const QString label = offsetLabel(zone.offsetFromUtc(when));
    return name.isEmpty() ? label : label + QLatin1Char(' ') + name;
}
