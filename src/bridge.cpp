#include "bridge.h"

#include <QDir>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QMessageBox>
#include <QSaveFile>
#include <QStandardPaths>

static QString T(const char *ko, const char *en)
{
    return QString::fromUtf8(QLocale::system().language() == QLocale::Korean ? ko : en);
}

static QString toJson(const QJsonObject &o)
{
    return QString::fromUtf8(QJsonDocument(o).toJson(QJsonDocument::Compact));
}

Bridge::Bridge(QWidget *parent) : QObject(parent), m_w(parent) {}

QString Bridge::docJson(const QString &path)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly) || f.size() > 20 * 1024 * 1024)
        return QString();
    QByteArray b = f.readAll();
    if (b.startsWith("\xEF\xBB\xBF"))
        b.remove(0, 3);
    QJsonObject o;
    o.insert(QStringLiteral("path"), path);
    o.insert(QStringLiteral("name"), QFileInfo(path).fileName());
    o.insert(QStringLiteral("text"), QString::fromUtf8(b));
    return toJson(o);
}

QString Bridge::openFile()
{
    const QString p = QFileDialog::getOpenFileName(
        m_w, T("파일 열기", "Open file"),
        QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation),
        T("Mixdown 문서 (*.mxd);;텍스트 (*.txt *.md);;모든 파일 (*)",
          "Mixdown document (*.mxd);;Text (*.txt *.md);;All files (*)"));
    if (p.isEmpty())
        return QString();
    const QString j = docJson(p);
    if (j.isEmpty())
        QMessageBox::warning(m_w, QStringLiteral("Mixdown"), T("파일을 읽을 수 없어요.", "Could not read the file."));
    return j;
}

QString Bridge::saveFile(const QString &text, const QString &name, const QString &extIn,
                         const QString &path, bool saveAs)
{
    const QString ext = (extIn == QLatin1String("html")) ? QStringLiteral("html") : QStringLiteral("mxd");
    QString file = path;
    if (file.isEmpty() || saveAs) {
        const QString docs = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
        const QString suggested = path.isEmpty() ? QDir(docs).filePath(name) : path;
        const QString filter = (ext == QLatin1String("html"))
            ? QStringLiteral("HTML (*.html)")
            : T("Mixdown 문서 (*.mxd)", "Mixdown document (*.mxd)");
        file = QFileDialog::getSaveFileName(m_w, T("저장", "Save"), suggested, filter);
        if (file.isEmpty())
            return QString();
    }
    const QString dotExt = QStringLiteral(".") + ext;
    if (!file.endsWith(dotExt, Qt::CaseInsensitive))
        file += dotExt;

    QSaveFile f(file);
    if (!f.open(QIODevice::WriteOnly) || f.write(text.toUtf8()) < 0 || !f.commit()) {
        QMessageBox::warning(m_w, QStringLiteral("Mixdown"), T("저장하지 못했어요.", "Could not save the file."));
        return QString();
    }
    QJsonObject o;
    o.insert(QStringLiteral("path"), file);
    o.insert(QStringLiteral("name"), QFileInfo(file).fileName());
    return toJson(o);
}

QString Bridge::initialFile()
{
    m_jsReady = true;
    const QString p = m_pending;
    m_pending.clear();
    return p.isEmpty() ? QString() : docJson(p);
}

void Bridge::openPath(const QString &path)
{
    if (!m_jsReady) {
        m_pending = path;
        return;
    }
    const QString j = docJson(path);
    if (!j.isEmpty())
        emit fileOpened(j);
}
