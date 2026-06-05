import QtQuick 2.0
import "../components"
import "../components/platform"

PageListPL {
    id: page
    title: qsTr("Apps")


    model: ListModel {
        id: appModel
    }


    delegate: ListItemPL {
        id: listItem

        LabelPL {
            text: name + " ("+version+")"
        }
        contentHeight: styler.themeItemSizeSmall// + (styler.themePaddingMedium * 2)
        onClicked: {
            console.log(JSON.stringify(details, null, 2))
        }
    }

    function downloadApps() {
        var http = new XMLHttpRequest();

        http.open("GET", "https://banglejs.com/apps/apps.json", true);

        // // set timeout
        var timer = Qt.createQmlObject("import QtQuick 2.9; Timer {interval: 5000; repeat: false; running: true;}", page, "MyTimer");
        timer.triggered.connect(function(){
            console.error("timeout reached http.abort()")
            http.abort();
        });

        http.onreadystatechange = function() {
            timer.running = false;
            // console.log("http request readyState " + http.readyState + " status: "+ http.status + " " +http.statusText)
            if (http.readyState === XMLHttpRequest.DONE) {
                console.log("http request DONE: " + http.status + " " +http.statusText )
                if (http.status === 200) {
                    try{
                        var result = JSON.parse(http.responseText);
                        appModel.clear();
                        // console.log(JSON.stringify(result[0]))
                        for (var i = 0; i < result.length; i++) {
                            var item = result[i];
                            // item.supports contain "BANGLEJS2"
                            appModel.append({"name": item.name, "version": item.version, details: item});
                        }

                        var resultStatus = (result.status !== undefined && result.status === 0);
                    } catch (e) {
                        console.error("http request: parse failed" + e)
                    }
                }
            }
        }
        http.send();

    }

    Component.onCompleted: {
        downloadApps();
    }
}