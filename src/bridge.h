#pragma once
#include <QObject>
#include <QString>

class QWidget;

// Bridge between the JS editor and C++. Registered with QWebChannel under the name "bridge".
class Bridge : public QObject
{
    Q_OBJECT
public:
    explicit Bridge(QWidget *parent);
    void openPath(const QString &path);              // file passed in by file association / macOS FileOpen
    void setPending(const QString &path) { m_pending = path; }

public slots:
    QString openFile();                              // open dialog -> JSON {path,name,text}
    QString saveFile(const QString &text, const QString &name, const QString &ext,
                     const QString &path, bool saveAs);   // save -> JSON {path,name}
    QString initialFile();                           // file to open at startup ("" if none)

signals:
    void menuAction(const QString &action);          // menu -> JS
    void fileOpened(const QString &json);            // a new file arrived while running -> JS

private:
    static QString docJson(const QString &path);
    QWidget *m_w;
    QString m_pending;
    bool m_jsReady = false;
};
