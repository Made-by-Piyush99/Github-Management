#include "BackendBridge.h"
#include <QDebug>
#include <QStandardPaths>
#include <QJSEngine>

BackendBridge::BackendBridge(QObject *parent)
    : QObject(parent)
{
    connect(&m_process, &QProcess::readyReadStandardOutput, this, &BackendBridge::onReadyReadStandardOutput);
    connect(&m_process, &QProcess::readyReadStandardError, this, &BackendBridge::onReadyReadStandardError);
    connect(&m_process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this, &BackendBridge::onProcessFinished);
    connect(&m_process, &QProcess::errorOccurred, this, &BackendBridge::onProcessError);
}

BackendBridge::~BackendBridge()
{
    stop();
}

QString BackendBridge::findPythonExecutable()
{
    // Check known paths
    QStringList candidates = {
        "python",
        "python3",
        "C:/Program Files/PyManager/python.exe",
        "C:/Users/Administrator/AppData/Local/Programs/Python/Python314/python.exe",
        "C:/Python314/python.exe",
        "C:/Python312/python.exe",
        "C:/Python311/python.exe"
    };

    for (const QString &c : candidates) {
        QString full = QStandardPaths::findExecutable(c);
        if (!full.isEmpty()) {
            return full;
        }
        if (QFileInfo::exists(c)) {
            return c;
        }
    }
    return "python";
}

void BackendBridge::start()
{
    if (m_process.state() != QProcess::NotRunning) {
        return;
    }

    m_starting = true;
    emit startingChanged(true);

    QString pythonExe = findPythonExecutable();
    QString workDir = QDir::currentPath();

    // Set UTF-8 encoding for Python
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert("PYTHONIOENCODING", "utf-8");
    env.insert("PYTHONUNBUFFERED", "1");
    m_process.setProcessEnvironment(env);
    m_process.setWorkingDirectory(workDir);

    QStringList args;
    args << "-m" << "backend.server";

    qDebug() << "[BackendBridge] Spawning Python worker:" << pythonExe << args << "in" << workDir;
    m_process.start(pythonExe, args);
}

void BackendBridge::stop()
{
    if (m_process.state() == QProcess::NotRunning) {
        return;
    }

    // Try sending polite shutdown request
    sendRequest("system.shutdown");
    if (!m_process.waitForFinished(2000)) {
        m_process.terminate();
        if (!m_process.waitForFinished(1000)) {
            m_process.kill();
        }
    }
}

void BackendBridge::restart()
{
    stop();
    start();
}

void BackendBridge::sendRequest(const QString &cmd, const QVariantMap &args, const QJSValue &callback)
{
    QString reqId = QUuid::createUuid().toString(QUuid::WithoutBraces);

    if (callback.isCallable()) {
        m_pendingRequests[reqId] = {cmd, callback};
    }

    QJsonObject reqObj;
    reqObj["id"] = reqId;
    reqObj["cmd"] = cmd;
    reqObj["args"] = QJsonObject::fromVariantMap(args);

    QJsonDocument doc(reqObj);
    QByteArray data = doc.toJson(QJsonDocument::Compact) + "\n";

    if (m_process.state() == QProcess::Running) {
        m_process.write(data);
    } else {
        qWarning() << "[BackendBridge] Cannot send request, process not running:" << cmd;
        if (callback.isCallable()) {
            QJSEngine *engine = qjsEngine(this);
            if (engine) {
                QJSValueList cbArgs;
                cbArgs << false << QJSValue(QJSValue::NullValue) << QString("Backend process is not running.");
                QJSValue mutableCb = callback;
                mutableCb.call(cbArgs);
            }
        }
    }
}

void BackendBridge::onReadyReadStandardOutput()
{
    m_outputBuffer.append(m_process.readAllStandardOutput());

    while (m_outputBuffer.contains('\n')) {
        int idx = m_outputBuffer.indexOf('\n');
        QByteArray lineBytes = m_outputBuffer.left(idx).trimmed();
        m_outputBuffer.remove(0, idx + 1);

        if (!lineBytes.isEmpty()) {
            processLine(QString::fromUtf8(lineBytes));
        }
    }
}

void BackendBridge::onReadyReadStandardError()
{
    QByteArray err = m_process.readAllStandardError();
    // Python logs to stderr - forward to debug output
    qDebug().noquote() << "[Backend.Log]" << QString::fromUtf8(err).trimmed();
}

void BackendBridge::processLine(const QString &line)
{
    QJsonParseError parseErr;
    QJsonDocument doc = QJsonDocument::fromJson(line.toUtf8(), &parseErr);
    if (parseErr.error != QJsonParseError::NoError || !doc.isObject()) {
        qWarning() << "[BackendBridge] Invalid JSON received from worker:" << line;
        return;
    }

    QJsonObject obj = doc.object();

    // Check if event
    if (obj.contains("event")) {
        QString eventName = obj["event"].toString();
        QVariantMap data = obj["data"].toObject().toVariantMap();

        if (eventName == "ready") {
            m_connected = true;
            m_starting = false;
            emit connectedChanged(true);
            emit startingChanged(false);
            emit readyReceived();
        } else if (eventName == "task_progress") {
            emit taskProgress(data["task_id"].toString(), data["percent"].toInt(), data["message"].toString());
        }

        emit eventReceived(eventName, data);
        return;
    }

    // Response matching
    QString reqId = obj["id"].toString();
    bool success = obj["success"].toBool();
    QVariant dataVariant = obj["data"].toVariant();
    QString errorMsg = obj["error"].toString();

    if (m_pendingRequests.contains(reqId)) {
        PendingRequest pending = m_pendingRequests.take(reqId);
        if (pending.callback.isCallable()) {
            QJSEngine *engine = qjsEngine(this);
            if (engine) {
                QJSValueList cbArgs;
                cbArgs << success;
                cbArgs << engine->toScriptValue(dataVariant);
                cbArgs << errorMsg;

                QJSValue mutableCb = pending.callback;
                mutableCb.call(cbArgs);
            }
        }
    }
}

void BackendBridge::onProcessFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    qDebug() << "[BackendBridge] Worker process finished with code:" << exitCode << "status:" << exitStatus;
    m_connected = false;
    m_starting = false;
    emit connectedChanged(false);
    emit startingChanged(false);
}

void BackendBridge::onProcessError(QProcess::ProcessError error)
{
    m_lastError = QString("Process error: %1").arg(error);
    qWarning() << "[BackendBridge]" << m_lastError;
    emit errorChanged(m_lastError);
}

void BackendBridge::openFolder(const QString &path)
{
    QDesktopServices::openUrl(QUrl::fromLocalFile(path));
}

void BackendBridge::openUrl(const QString &url)
{
    QDesktopServices::openUrl(QUrl(url));
}

QString BackendBridge::selectFolder(const QString &title, const QString &defaultDir)
{
    return QFileDialog::getExistingDirectory(nullptr, title, defaultDir, QFileDialog::ShowDirsOnly | QFileDialog::DontResolveSymlinks);
}

QString BackendBridge::selectSaveFile(const QString &title, const QString &defaultName, const QString &filter)
{
    return QFileDialog::getSaveFileName(nullptr, title, defaultName, filter);
}

void BackendBridge::copyToClipboard(const QString &text)
{
    QClipboard *clipboard = QGuiApplication::clipboard();
    if (clipboard) {
        clipboard->setText(text);
    }
}
