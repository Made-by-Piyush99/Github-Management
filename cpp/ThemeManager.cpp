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
    return m_isDark ? QColor("#0B0E14") : QColor("#F8FAFC");
}

QColor ThemeManager::bgSecondary() const
{
    return m_isDark ? QColor("#111620") : QColor("#FFFFFF");
}

QColor ThemeManager::bgCard() const
{
    return m_isDark ? QColor("#161D2A") : QColor("#FFFFFF");
}

QColor ThemeManager::bgCardHover() const
{
    return m_isDark ? QColor("#1E2738") : QColor("#F1F5F9");
}

QColor ThemeManager::bgInput() const
{
    return m_isDark ? QColor("#0E131C") : QColor("#FFFFFF");
}

QColor ThemeManager::borderPrimary() const
{
    return m_isDark ? QColor("#222C3D") : QColor("#E2E8F0");
}

QColor ThemeManager::borderSecondary() const
{
    return m_isDark ? QColor("#313F56") : QColor("#CBD5E1");
}

QColor ThemeManager::textPrimary() const
{
    return m_isDark ? QColor("#F1F5F9") : QColor("#0F172A");
}

QColor ThemeManager::textSecondary() const
{
    return m_isDark ? QColor("#94A3B8") : QColor("#475569");
}

QColor ThemeManager::textMuted() const
{
    return m_isDark ? QColor("#64748B") : QColor("#94A3B8");
}

QColor ThemeManager::accent() const
{
    return m_isDark ? QColor("#38BDF8") : QColor("#0284C7");
}

QColor ThemeManager::accentHover() const
{
    return m_isDark ? QColor("#7DD3FC") : QColor("#0369A1");
}

QColor ThemeManager::accentMuted() const
{
    return m_isDark ? QColor(56, 189, 248, 28) : QColor(2, 132, 199, 22);
}

QColor ThemeManager::success() const
{
    return m_isDark ? QColor("#10B981") : QColor("#059669");
}

QColor ThemeManager::warning() const
{
    return m_isDark ? QColor("#F59E0B") : QColor("#D97706");
}

QColor ThemeManager::danger() const
{
    return m_isDark ? QColor("#F43F5E") : QColor("#E11D48");
}

QColor ThemeManager::info() const
{
    return m_isDark ? QColor("#38BDF8") : QColor("#0284C7");
}
