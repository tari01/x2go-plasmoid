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

import QtQuick 2.12
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.core 2.0 as Core
import org.kde.plasma.plasmoid 2.0
import org.x2go.plasmoid 1.0 as X2Go

Item
{
    id: main
    Plasmoid.toolTipMainText: i18n ("X2Go session control")
    Plasmoid.toolTipSubText: i18n ("You are in an active X2Go session")
    property bool bSession: X2Go.Helpers.isSession ()
    Plasmoid.status: bSession ? Core.Types.ActiveStatus : Core.Types.HiddenStatus

    ColumnLayout
    {
        anchors.fill: parent

        RoundButton
        {
            id: button
            text: i18n ("Suspend this session")
            icon.name: "system-shutdown"
            Layout.preferredWidth: width
            Layout.preferredHeight: width
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            onClicked:
            {
                X2Go.Helpers.suspendSession ()
            }
        }
    }
}
