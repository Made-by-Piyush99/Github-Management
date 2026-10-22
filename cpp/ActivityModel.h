#pragma once

#include <QAbstractListModel>
#include <QVariantList>
#include <QVariantMap>

class ActivityModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum ActivityRoles {
        IdRole = Qt::UserRole + 1,
        ProjectIdRole,
        ProjectNameRole,
        OpTypeRole,
        StatusRole,
        StartedAtRole,
        CompletedAtRole,
        DurationMsRole,
        ErrorMessageRole,
    };

    explicit ActivityModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void setActivities(const QVariantList &list);
    Q_INVOKABLE void appendActivity(const QVariantMap &op);
    Q_INVOKABLE void clear();

signals:
    void countChanged();

private:
    QVariantList m_activities;
};
