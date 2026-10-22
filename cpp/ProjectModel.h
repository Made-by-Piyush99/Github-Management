#pragma once

#include <QAbstractListModel>
#include <QVariantList>
#include <QVariantMap>

class ProjectModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum ProjectRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        LocalPathRole,
        GitRemoteRole,
        DefaultBranchRole,
        CurrentBranchRole,
        StatusRole,
        IsPinnedRole,
        UncommittedCountRole,
        AheadRole,
        BehindRole,
        LastCommitSubjectRole,
        LastCommitAuthorRole,
        LastCommitDateRole,
        LastPushRole,
        LastPullRole,
        IsGitRepoRole,
        HasGitHubRole,
        ExistsRole,
    };

    explicit ProjectModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void setProjects(const QVariantList &list);
    Q_INVOKABLE void updateProject(const QVariantMap &project);
    Q_INVOKABLE void removeProject(const QString &id);
    Q_INVOKABLE QVariantMap get(int index) const;
    Q_INVOKABLE int indexOf(const QString &id) const;

signals:
    void countChanged();

private:
    QVariantList m_projects;
};
