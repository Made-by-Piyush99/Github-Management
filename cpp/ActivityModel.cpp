#include "ActivityModel.h"

ActivityModel::ActivityModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ActivityModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_activities.size();
}

QVariant ActivityModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_activities.size()) {
        return QVariant();
    }

    QVariantMap item = m_activities.at(index.row()).toMap();

    switch (role) {
    case IdRole:
        return item.value("id");
    case ProjectIdRole:
        return item.value("project_id");
    case ProjectNameRole:
        return item.value("project_name");
    case OpTypeRole:
        return item.value("op_type");
    case StatusRole:
        return item.value("status");
    case StartedAtRole:
        return item.value("started_at");
    case CompletedAtRole:
        return item.value("completed_at");
    case DurationMsRole:
        return item.value("duration_ms");
    case ErrorMessageRole:
        return item.value("error_message");
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> ActivityModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[ProjectIdRole] = "project_id";
    roles[ProjectNameRole] = "project_name";
    roles[OpTypeRole] = "op_type";
    roles[StatusRole] = "status";
    roles[StartedAtRole] = "started_at";
    roles[CompletedAtRole] = "completed_at";
    roles[DurationMsRole] = "duration_ms";
    roles[ErrorMessageRole] = "error_message";
    return roles;
}

void ActivityModel::setActivities(const QVariantList &list)
{
    beginResetModel();
    m_activities = list;
    endResetModel();
    emit countChanged();
}

void ActivityModel::appendActivity(const QVariantMap &op)
{
    beginInsertRows(QModelIndex(), 0, 0);
    m_activities.prepend(op);
    endInsertRows();
    emit countChanged();
}

void ActivityModel::clear()
{
    beginResetModel();
    m_activities.clear();
    endResetModel();
    emit countChanged();
}
