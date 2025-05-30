/* -*- coding: utf-8-unix -*-
 *
 * Copyright (C) 2018 Rinigus
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.12

Label {
    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

    elide: {
        if (truncMode === truncModes.elide) return Text.ElideRight;
        if (truncMode === truncModes.fade) return Text.ElideRight;
        return Text.ElideNone;
    }
    font.pixelSize: styler.themeFontSizeMedium
    wrapMode: Text.WordWrap

    property int truncMode: truncModes.none
}
