#pragma once

#include <QObject>
#include <QColor>

class ThemeManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isDark READ isDark WRITE setIsDark NOTIFY themeChanged)
    Q_PROPERTY(QColor bgPrimary READ bgPrimary NOTIFY themeChanged)
    Q_PROPERTY(QColor bgSecondary READ bgSecondary NOTIFY themeChanged)
    Q_PROPERTY(QColor bgCard READ bgCard NOTIFY themeChanged)
    Q_PROPERTY(QColor bgCardHover READ bgCardHover NOTIFY themeChanged)
    Q_PROPERTY(QColor bgInput READ bgInput NOTIFY themeChanged)
    Q_PROPERTY(QColor borderPrimary READ borderPrimary NOTIFY themeChanged)
    Q_PROPERTY(QColor borderSecondary READ borderSecondary NOTIFY themeChanged)
    Q_PROPERTY(QColor textPrimary READ textPrimary NOTIFY themeChanged)
    Q_PROPERTY(QColor textSecondary READ textSecondary NOTIFY themeChanged)
    Q_PROPERTY(QColor textMuted READ textMuted NOTIFY themeChanged)
    Q_PROPERTY(QColor accent READ accent NOTIFY themeChanged)
    Q_PROPERTY(QColor accentHover READ accentHover NOTIFY themeChanged)
    Q_PROPERTY(QColor accentMuted READ accentMuted NOTIFY themeChanged)
    Q_PROPERTY(QColor success READ success NOTIFY themeChanged)
    Q_PROPERTY(QColor warning READ warning NOTIFY themeChanged)
    Q_PROPERTY(QColor danger READ danger NOTIFY themeChanged)
    Q_PROPERTY(QColor info READ info NOTIFY themeChanged)

public:
    explicit ThemeManager(QObject *parent = nullptr);

    bool isDark() const { return m_isDark; }
    void setIsDark(bool dark);

    Q_INVOKABLE void toggleTheme();

    QColor bgPrimary() const;
    QColor bgSecondary() const;
    QColor bgCard() const;
    QColor bgCardHover() const;
    QColor bgInput() const;
    QColor borderPrimary() const;
    QColor borderSecondary() const;
    QColor textPrimary() const;
    QColor textSecondary() const;
    QColor textMuted() const;
    QColor accent() const;
    QColor accentHover() const;
    QColor accentMuted() const;
    QColor success() const;
    QColor warning() const;
    QColor danger() const;
    QColor info() const;

signals:
    void themeChanged();

private:
    bool m_isDark{true};
};
