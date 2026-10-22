#include "ProjectModel.h"

ProjectModel::ProjectModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int ProjectModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_projects.size();
}

QVariant ProjectModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_projects.size()) {
        return QVariant();
    }

    QVariantMap p = m_projects.at(index.row()).toMap();

    switch (role) {
    case IdRole:
        return p.value("id");
    case NameRole:
        return p.value("name");
    case LocalPathRole:
        return p.value("local_path");
    case GitRemoteRole:
        return p.value("primary_remote_url", p.value("git_remote"));
    case DefaultBranchRole:
        return p.value("default_branch");
    case CurrentBranchRole:
        return p.value("current_branch");
    case StatusRole:
        return p.value("status");
    case IsPinnedRole:
        return p.value("is_pinned", 0).toInt() == 1;
    case UncommittedCountRole:
        return p.value("uncommitted_count", 0);
    case AheadRole:
        return p.value("ahead", 0);
    case BehindRole:
        return p.value("behind", 0);
    case LastCommitSubjectRole: {
        QVariantMap commit = p.value("last_commit").toMap();
        return commit.value("message");
    }
    case LastCommitAuthorRole: {
        QVariantMap commit = p.value("last_commit").toMap();
        return commit.value("author_name");
    }
    case LastCommitDateRole: {
        QVariantMap commit = p.value("last_commit").toMap();
        return commit.value("date");
    }
    case LastPushRole:
        return p.value("last_successful_push");
    case LastPullRole:
        return p.value("last_successful_pull");
    case IsGitRepoRole:
        return p.value("is_git_repo", false);
    case HasGitHubRole:
        return p.value("has_github_remote", false);
    case ExistsRole:
        return p.value("exists", true);
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> ProjectModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    roles[LocalPathRole] = "local_path";
    roles[GitRemoteRole] = "git_remote";
    roles[DefaultBranchRole] = "default_branch";
    roles[CurrentBranchRole] = "current_branch";
    roles[StatusRole] = "status";
    roles[IsPinnedRole] = "is_pinned";
    roles[UncommittedCountRole] = "uncommitted_count";
    roles[AheadRole] = "ahead";
    roles[BehindRole] = "behind";
    roles[LastCommitSubjectRole] = "last_commit_subject";
    roles[LastCommitAuthorRole] = "last_commit_author";
    roles[LastCommitDateRole] = "last_commit_date";
    roles[LastPushRole] = "last_successful_push";
    roles[LastPullRole] = "last_successful_pull";
    roles[IsGitRepoRole] = "is_git_repo";
    roles[HasGitHubRole] = "has_github_remote";
    roles[ExistsRole] = "exists";
    return roles;
}

void ProjectModel::setProjects(const QVariantList &list)
{
    beginResetModel();
    m_projects = list;
    endResetModel();
    emit countChanged();
}

void ProjectModel::updateProject(const QVariantMap &project)
{
    QString id = project.value("id").toString();
    for (int i = 0; i < m_projects.size(); ++i) {
        if (m_projects.at(i).toMap().value("id").toString() == id) {
            m_projects[i] = project;
            emit dataChanged(index(i), index(i));
            return;
        }
    }
    // If not found, append
    beginInsertRows(QModelIndex(), m_projects.size(), m_projects.size());
    m_projects.append(project);
    endInsertRows();
    emit countChanged();
}

void ProjectModel::removeProject(const QString &id)
{
    for (int i = 0; i < m_projects.size(); ++i) {
        if (m_projects.at(i).toMap().value("id").toString() == id) {
            beginRemoveRows(QModelIndex(), i, i);
            m_projects.removeAt(i);
            endRemoveRows();
            emit countChanged();
            return;
        }
    }
}

QVariantMap ProjectModel::get(int index) const
{
    if (index >= 0 && index < m_projects.size()) {
        return m_projects.at(index).toMap();
    }
    return QVariantMap();
}

int ProjectModel::indexOf(const QString &id) const
{
    for (int i = 0; i < m_projects.size(); ++i) {
        if (m_projects.at(i).toMap().value("id").toString() == id) {
            return i;
        }
    }
    return -1;
}
