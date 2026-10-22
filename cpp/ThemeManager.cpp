#include "ThemeManager.h"

ThemeManager::ThemeManager(QObject *parent)
    : QObject(parent), m_isDark(true)
{
}

void ThemeManager::setIsDark(bool dark)
{
    if (m_isDark != dark) {
        m_isDark = dark;
        emit themeChanged();
    }
}

void ThemeManager::toggleTheme()
{
    setIsDark(!m_isDark);
}

QColor ThemeManager::bgPrimary() const
{
    return m_isDark ? QColor("#0F1117") : QColor("#F6F8FA");
}

QColor ThemeManager::bgSecondary() const
{
    return m_isDark ? QColor("#161B22") : QColor("#FFFFFF");
}

QColor ThemeManager::bgCard() const
{
    return m_isDark ? QColor("#1A202C") : QColor("#FFFFFF");
}

QColor ThemeManager::bgCardHover() const
{
    return m_isDark ? QColor("#242C3D") : QColor("#F3F4F6");
}

QColor ThemeManager::bgInput() const
{
    return m_isDark ? QColor("#12161F") : QColor("#FFFFFF");
}

QColor ThemeManager::borderPrimary() const
{
    return m_isDark ? QColor("#2D3748") : QColor("#D0D7DE");
}

QColor ThemeManager::borderSecondary() const
{
    return m_isDark ? QColor("#3B4456") : QColor("#E1E4E8");
}

QColor ThemeManager::textPrimary() const
{
    return m_isDark ? QColor("#F0F6FC") : QColor("#1F2328");
}

QColor ThemeManager::textSecondary() const
{
    return m_isDark ? QColor("#8B949E") : QColor("#59636E");
}

QColor ThemeManager::textMuted() const
{
    return m_isDark ? QColor("#64748B") : QColor("#8C959F");
}

QColor ThemeManager::accent() const
{
    return m_isDark ? QColor("#3B82F6") : QColor("#0969DA");
}

QColor ThemeManager::accentHover() const
{
    return m_isDark ? QColor("#60A5FA") : QColor("#218BFF");
}

QColor ThemeManager::accentMuted() const
{
    return m_isDark ? QColor(59, 130, 246, 38) : QColor(9, 105, 218, 30);
}

QColor ThemeManager::success() const
{
    return m_isDark ? QColor("#22C55E") : QColor("#16A34A");
}

QColor ThemeManager::warning() const
{
    return m_isDark ? QColor("#EAB308") : QColor("#CA8A04");
}

QColor ThemeManager::danger() const
{
    return m_isDark ? QColor("#EF4444") : QColor("#DC2626");
}

QColor ThemeManager::info() const
{
    return m_isDark ? QColor("#06B6D4") : QColor("#0284C7");
}
