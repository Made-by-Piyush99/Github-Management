#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QIcon>
#include <QDir>
#include <QDebug>
#include <QFile>
#include <QTextStream>

#include "cpp/BackendBridge.h"
#include "cpp/ProjectModel.h"
#include "cpp/ActivityModel.h"
#include "cpp/FileStatusModel.h"
#include "cpp/ThemeManager.h"

void customLogHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QFile logFile("qml_debug.log");
    if (logFile.open(QIODevice::WriteOnly | QIODevice::Append)) {
        QTextStream ts(&logFile);
        ts << msg << "\n";
    }
}

int main(int argc, char *argv[])
{
    qInstallMessageHandler(customLogHandler);
    // High DPI scaling is handled automatically in Qt 6
    QApplication app(argc, argv);

    app.setOrganizationName("DevSyncStudio");
    app.setOrganizationDomain("devsync.studio");
    app.setApplicationName("DevSync Studio");
    app.setApplicationVersion("1.0.0");

    // Use Basic/Fusion style for custom animated QML components
    QQuickStyle::setStyle("Basic");

    QQmlApplicationEngine engine;

    // Create models and bridge instances
    auto *backendBridge = new BackendBridge(&app);
    auto *projectModel = new ProjectModel(&app);
    auto *activityModel = new ActivityModel(&app);
    auto *fileStatusModel = new FileStatusModel(&app);
    auto *themeManager = new ThemeManager(&app);

    // Register context properties to QML
    QQmlContext *rootCtx = engine.rootContext();
    rootCtx->setContextProperty("backendBridge", backendBridge);
    rootCtx->setContextProperty("projectModel", projectModel);
    rootCtx->setContextProperty("activityModel", activityModel);
    rootCtx->setContextProperty("fileStatusModel", fileStatusModel);
    rootCtx->setContextProperty("themeManager", themeManager);

    // Add import paths for QML modules
    engine.addImportPath(app.applicationDirPath());
    engine.addImportPath("qrc:/");

    // Start background Python worker
    backendBridge->start();

    // Load Main.qml (supports both resource and direct filesystem for fast iteration)
    const QUrl url(QStringLiteral("qrc:/ui/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                qCritical() << "Failed to load Main.qml!";
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection);

    engine.load(url);

    // Fallback to loading from local file if qrc was not found
    if (engine.rootObjects().isEmpty()) {
        QString localQml = QDir::current().filePath("ui/Main.qml");
        qDebug() << "Fallback loading QML from local filesystem:" << localQml;
        engine.load(QUrl::fromLocalFile(localQml));
    }

    int ret = app.exec();

    // Cleanly stop backend worker on exit
    backendBridge->stop();

    return ret;
}
