#include "mainwindow.h"
#include "bridge.h"

#include <QAction>
#include <QDesktopServices>
#include <QKeySequence>
#include <QLocale>
#include <QMenu>
#include <QMenuBar>
#include <QMessageBox>
#include <QUrl>
#include <QWebChannel>
#include <QWebEngineProfile>
#include <QWebEngineSettings>
#include <QWebEngineView>
#include <functional>

static QString T(const char *ko, const char *en)
{
    return QString::fromUtf8(QLocale::system().language() == QLocale::Korean ? ko : en);
}

// Only qrc pages are opened inside the app; web links go to the default browser.
class Page : public QWebEnginePage
{
public:
    using QWebEnginePage::QWebEnginePage;

protected:
    bool acceptNavigationRequest(const QUrl &url, NavigationType, bool) override
    {
        const QString s = url.scheme();
        if (s == QLatin1String("qrc") || s == QLatin1String("about") || s == QLatin1String("blob")
            || s == QLatin1String("data"))
            return true;
        QDesktopServices::openUrl(url);
        return false;
    }

    QWebEnginePage *createWindow(WebWindowType) override
    {
        QWebEnginePage *tmp = new QWebEnginePage(profile(), this);
        connect(tmp, &QWebEnginePage::urlChanged, this, [tmp](const QUrl &u) {
            if (u.isEmpty() || u.scheme() == QLatin1String("about"))
                return;
            QDesktopServices::openUrl(u);
            tmp->deleteLater();
        });
        return tmp;
    }
};

MainWindow::MainWindow(QWidget *parent) : QMainWindow(parent)
{
    setWindowTitle(QStringLiteral("Mixdown"));
    resize(1280, 820);

    m_view = new QWebEngineView(this);
    Page *page = new Page(QWebEngineProfile::defaultProfile(), m_view);
    m_view->setPage(page);
    page->settings()->setAttribute(QWebEngineSettings::LocalStorageEnabled, true);

    m_bridge = new Bridge(this);
    QWebChannel *channel = new QWebChannel(page);
    channel->registerObject(QStringLiteral("bridge"), m_bridge);
    page->setWebChannel(channel);

    setCentralWidget(m_view);
    buildMenu();

    connect(m_view, &QWebEngineView::titleChanged, this, [this](const QString &t) {
        setWindowTitle(t.isEmpty() ? QStringLiteral("Mixdown") : t);
    });
    m_view->load(QUrl(QStringLiteral("qrc:/index.html")));
}

void MainWindow::openPath(const QString &path) { m_bridge->openPath(path); }
void MainWindow::setPending(const QString &path) { m_bridge->setPending(path); }

void MainWindow::act(const char *name)
{
    emit m_bridge->menuAction(QString::fromLatin1(name));
}

void MainWindow::buildMenu()
{
    auto add = [this](QMenu *menu, const QString &text, const QKeySequence &ks, std::function<void()> fn) {
        QAction *a = menu->addAction(text);
        if (!ks.isEmpty())
            a->setShortcut(ks);
        connect(a, &QAction::triggered, this, [fn]() { fn(); });
    };

    QMenu *file = menuBar()->addMenu(T("파일(&F)", "&File"));
    add(file, T("열기…", "Open…"), QKeySequence::Open, [this] { act("open"); });
    add(file, T("저장", "Save"), QKeySequence::Save, [this] { act("save"); });
    add(file, T("다른 이름으로 저장…", "Save As…"), QKeySequence::SaveAs, [this] { act("saveas"); });
    add(file, T("HTML 내보내기…", "Export HTML…"), QKeySequence(), [this] { act("html"); });
    file->addSeparator();
    add(file, T("끝내기", "Quit"), QKeySequence::Quit, [this] { close(); });

    QMenu *edit = menuBar()->addMenu(T("편집(&E)", "&Edit"));
    QWebEnginePage *p = m_view->page();
    add(edit, T("실행 취소", "Undo"), QKeySequence::Undo, [p] { p->triggerAction(QWebEnginePage::Undo); });
    add(edit, T("다시 실행", "Redo"), QKeySequence::Redo, [p] { p->triggerAction(QWebEnginePage::Redo); });
    edit->addSeparator();
    add(edit, T("잘라내기", "Cut"), QKeySequence::Cut, [p] { p->triggerAction(QWebEnginePage::Cut); });
    add(edit, T("복사", "Copy"), QKeySequence::Copy, [p] { p->triggerAction(QWebEnginePage::Copy); });
    add(edit, T("붙여넣기", "Paste"), QKeySequence::Paste, [p] { p->triggerAction(QWebEnginePage::Paste); });
    add(edit, T("모두 선택", "Select All"), QKeySequence::SelectAll, [p] { p->triggerAction(QWebEnginePage::SelectAll); });

    QMenu *view = menuBar()->addMenu(T("보기(&V)", "&View"));
    add(view, T("확대", "Zoom In"), QKeySequence::ZoomIn, [this] { m_view->setZoomFactor(m_view->zoomFactor() + 0.1); });
    add(view, T("축소", "Zoom Out"), QKeySequence::ZoomOut, [this] { m_view->setZoomFactor(m_view->zoomFactor() - 0.1); });
    add(view, T("원래 크기", "Actual Size"), QKeySequence(Qt::CTRL | Qt::Key_0), [this] { m_view->setZoomFactor(1.0); });
    view->addSeparator();
    add(view, T("전체 화면", "Full Screen"), QKeySequence(Qt::Key_F11), [this] {
        isFullScreen() ? showNormal() : showFullScreen();
    });

    QMenu *help = menuBar()->addMenu(T("도움말(&H)", "&Help"));
    add(help, T("Mixdown 정보", "About Mixdown"), QKeySequence(), [this] {
        QMessageBox::about(this, QStringLiteral("Mixdown"),
                           QStringLiteral("Mixdown %1\nQt %2")
                               .arg(QStringLiteral(MIXDOWN_VERSION), QString::fromLatin1(qVersion())));
    });
}
