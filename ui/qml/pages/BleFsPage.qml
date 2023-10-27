import QtQuick 2.0
import uk.co.piggz.amazfish 1.0
import QtQuick.Layouts 1.1
import "../components/"
import "../components/platform"

PagePL {
    id: page
    title: qsTr("FileSystem")

    property string path: "/"

    onPathChanged: {
        reloadPath()
    }


    ListModel {
        id: filesModel
        ListElement { filename: "test" }
        ListElement { filename: "test" }
        ListElement { filename: "test" }
        ListElement { filename: "test" }
    }

    Column {
        id: column
        width: parent.width
        anchors.top: parent.top
        anchors.margins: styler.themePaddingMedium
        spacing: styler.themePaddingLarge

        ListViewPL {
            id: listView
            model: filesModel
            height: app.height - styler.themePaddingLarge
            width: parent.width

            delegate: ListItemPL {
                contentHeight: styler.themeItemSizeSmall

                onClicked: {
//                    app.pages.pop();
                }

                LabelPL {
                    width: page.width/4
                    anchors.verticalCenter: parent.verticalCenter
                    text: model.filename
                }

            }
        }

    }

    function reloadPath() {
        var list = DaemonInterfaceInstance.getFileList(path)
        filesModel.clear();
        for (var i = 0; i < list.length; i++) {
            filesModel.append({"filename": list[i]})
        }
    }

    Component.onCompleted: {
        reloadPath()
    }

}
