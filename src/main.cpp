#include <QApplication>
#include <QFileInfo>
#include <QFileOpenEvent>
#include <QStringList>

#include "mainwindow.h"

// On macOS, double-clicking a file is reported as a FileOpen event instead of argv.
class App : public QApplication
{
public:
    using QApplication::QApplication;
    MainWindow *win = nullptr;
    QString pending;

protected:
    bool event(QEvent *e) override
    {
        if (e->type() == QEvent::FileOpen) {
            const QString f = static_cast<QFileOpenEvent *>(e)->file();
            if (win)
                win->openPath(f);
            else
                pending = f;
            return true;
        }
        return QApplication::event(e);
    }
};

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
#endif
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);

    App app(argc, argv);
    app.setOrganizationName(QStringLiteral("Mixdown"));
    app.setApplicationName(QStringLiteral("Mixdown"));
    app.setApplicationVersion(QStringLiteral(MIXDOWN_VERSION));

    MainWindow w;
    app.win = &w;

    QString file = app.pending;
    const QStringList args = app.arguments();
    for (int i = 1; i < args.size(); ++i) {
        if (args.at(i).endsWith(QLatin1String(".mxd"), Qt::CaseInsensitive) && QFileInfo::exists(args.at(i)))
            file = args.at(i);
    }
    if (!file.isEmpty())
        w.setPending(file);

    w.show();
    return app.exec();
}
