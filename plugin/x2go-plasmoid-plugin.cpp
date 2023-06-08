/*
* Copyright 2023 Robert Tari
*
* This program is free software: you can redistribute it and/or modify it
* under the terms of the GNU General Public License version 3, as published
* by the Free Software Foundation.
*
* This program is distributed in the hope that it will be useful, but
* WITHOUT ANY WARRANTY; without even the implied warranties of
* MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
* PURPOSE.  See the GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License along
* with this program.  If not, see <http://www.gnu.org/licenses/>.
*
* Authors:
*     Robert Tari <robert@tari.in>
*/

#include <QQmlExtensionPlugin>
#include <QQmlEngine>
#include <QProcess>

class Helpers : public QObject
{
    Q_OBJECT

public:

    Q_INVOKABLE bool isSession ()
    {
        this->sSessionId = qgetenv("X2GO_SESSION");

        if (this->sSessionId.isEmpty())
        {
            return false;
        }

        return true;
    }

    Q_INVOKABLE void suspendSession ()
    {
        QString sCommand = "x2gosuspend-session";
        QStringList lAgs = {this->sSessionId};
        QProcess *pProcess = new QProcess ();
        pProcess->start (sCommand, lAgs);
    }

private:

    QString sSessionId;
};

class X2GoPlasmoidPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA (IID "org.qt-project.Qt.QQmlExtensionInterface")

public:

    void registerTypes(const char *sUri) override
    {
        qmlRegisterSingletonType<Helpers> (sUri, 1, 0, "Helpers", [](QQmlEngine *, QJSEngine *)
        {
            return new Helpers();
        });
    }
};

#include "x2go-plasmoid-plugin.moc"
