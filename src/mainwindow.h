#pragma once
#include <QMainWindow>

class QWebEngineView;
class Bridge;

class MainWindow : public QMainWindow
{
    Q_OBJECT
public:
    explicit MainWindow(QWidget *parent = nullptr);
    void openPath(const QString &path);
    void setPending(const QString &path);

private:
    void buildMenu();
    void act(const char *name);

    QWebEngineView *m_view;
    Bridge *m_bridge;
};
