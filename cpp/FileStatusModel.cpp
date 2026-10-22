#include "FileStatusModel.h"

FileStatusModel::FileStatusModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int FileStatusModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_files.size();
}

QVariant FileStatusModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_files.size()) {
        return QVariant();
    }

    QVariantMap f = m_files.at(index.row()).toMap();

    switch (role) {
    case PathRole:
        return f.value("path");
    case IndexStatusRole:
        return f.value("index_status");
    case WorktreeStatusRole:
        return f.value("worktree_status");
    case IsStagedRole:
        return f.value("is_staged", false);
    case IsModifiedRole:
        return f.value("is_modified", false);
    case IsUntrackedRole:
        return f.value("is_untracked", false);
    case IsConflictRole:
        return f.value("is_conflict", false);
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> FileStatusModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[PathRole] = "path";
    roles[IndexStatusRole] = "index_status";
    roles[WorktreeStatusRole] = "worktree_status";
    roles[IsStagedRole] = "is_staged";
    roles[IsModifiedRole] = "is_modified";
    roles[IsUntrackedRole] = "is_untracked";
    roles[IsConflictRole] = "is_conflict";
    return roles;
}

void FileStatusModel::setFiles(const QVariantList &list)
{
    beginResetModel();
    m_files = list;
    endResetModel();
    emit countChanged();
    emit countsChanged();
}

void FileStatusModel::clear()
{
    beginResetModel();
    m_files.clear();
    endResetModel();
    emit countChanged();
    emit countsChanged();
}

QVariantMap FileStatusModel::get(int index) const
{
    if (index >= 0 && index < m_files.size()) {
        return m_files.at(index).toMap();
    }
    return QVariantMap();
}

int FileStatusModel::stagedCount() const
{
    int count = 0;
    for (const QVariant &v : m_files) {
        if (v.toMap().value("is_staged", false).toBool()) {
            count++;
        }
    }
    return count;
}

int FileStatusModel::unstagedCount() const
{
    int count = 0;
    for (const QVariant &v : m_files) {
        QVariantMap m = v.toMap();
        if (m.value("is_modified", false).toBool() || m.value("is_untracked", false).toBool()) {
            count++;
        }
    }
    return count;
}
