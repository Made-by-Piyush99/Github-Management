#pragma once

#include <QAbstractListModel>
#include <QVariantList>
#include <QVariantMap>

class FileStatusModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(int stagedCount READ stagedCount NOTIFY countsChanged)
    Q_PROPERTY(int unstagedCount READ unstagedCount NOTIFY countsChanged)

public:
    enum FileRoles {
        PathRole = Qt::UserRole + 1,
        IndexStatusRole,
        WorktreeStatusRole,
        IsStagedRole,
        IsModifiedRole,
        IsUntrackedRole,
        IsConflictRole,
    };

    explicit FileStatusModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void setFiles(const QVariantList &list);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QVariantMap get(int index) const;

    int stagedCount() const;
    int unstagedCount() const;

signals:
    void countChanged();
    void countsChanged();

private:
    QVariantList m_files;
};
