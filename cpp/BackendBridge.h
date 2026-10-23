#pragma once

#include <QObject>
#include <QProcess>
#include <QJsonObject>
#include <QJsonDocument>
#include <QVariantMap>
#include <QMap>
#include <QJSValue>
#include <QFileDialog>
#include <QClipboard>
#include <QGuiApplication>
#include <QDesktopServices>
#include <QUrl>
#include <QFileInfo>
#include <QDir>
#include <QUuid>

class BackendBridge : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isConnected READ isConnected NOTIFY connectedChanged)
    Q_PROPERTY(bool isStarting READ isStarting NOTIFY startingChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY errorChanged)

public:
    explicit BackendBridge(QObject *parent = nullptr);
    ~BackendBridge() override;

    bool isConnected() const { return m_connected; }
    bool isStarting() const { return m_starting; }
    QString lastError() const { return m_lastError; }

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void restart();
    bool waitForReady(int timeoutMs = 6000);

    // Sends a command to the backend worker with an optional JS callback function(success, data, error)
    Q_INVOKABLE void sendRequest(const QString &cmd, const QVariantMap &args = QVariantMap(), const QJSValue &callback = QJSValue());

    // Native utilities
    Q_INVOKABLE void openFolder(const QString &path);
    Q_INVOKABLE void openUrl(const QString &url);
    Q_INVOKABLE QString selectFolder(const QString &title = "Select Folder", const QString &defaultDir = "");
    Q_INVOKABLE QString selectSaveFile(const QString &title = "Save File", const QString &defaultName = "", const QString &filter = "All Files (*.*)");
    Q_INVOKABLE void copyToClipboard(const QString &text);

signals:
    void connectedChanged(bool connected);
    void startingChanged(bool starting);
    void errorChanged(const QString &error);
    void readyReceived();
    void eventReceived(const QString &eventName, const QVariantMap &data);
    void taskProgress(const QString &taskId, int percent, const QString &message);

private slots:
    void onReadyReadStandardOutput();
    void onReadyReadStandardError();
    void onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onProcessError(QProcess::ProcessError error);

private:
    void processLine(const QString &line);
    QString findPythonExecutable();

    QProcess m_process;
    bool m_connected{false};
    bool m_starting{false};
    QString m_lastError;
    QByteArray m_outputBuffer;
    QList<QByteArray> m_outgoingQueue;

    struct PendingRequest {
        QString cmd;
        QJSValue callback;
    };
    QMap<QString, PendingRequest> m_pendingRequests;
};
