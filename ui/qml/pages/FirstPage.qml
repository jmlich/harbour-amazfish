import QtQuick 2.0
import org.SfietKonstantin.weatherfish 1.0
import uk.co.piggz.amazfish 1.0
import QtQuick.Layouts 1.1
import "../components/"
import "../components/platform"

PagePL {
    id: page
    title: "Amazfish"

    function unpairAccepted() {
        DaemonInterfaceInstance.disconnect();
        DaemonInterfaceInstance.unpair()
        AmazfishConfig.pairedAddress = "";
        AmazfishConfig.pairedName = "";
        AmazfishConfig.pairedType = "";

    }

    pageMenu: PageMenuPL {
//        PageMenuItemPL {
//            text: qsTr("Test Icons")
//            onClicked: app.pages.push(Qt.resolvedUrl("TestIconsPage.qml"))
//        }
        PageMenuItemPL {
            text: qsTr("Pair with watch")
            onClicked: {
                if (AmazfishConfig.pairedAddress) {
                    var obj = app.pages.push(Qt.resolvedUrl("UnpairDeviceDialog.qml"));
                    obj.acceptDestination = Qt.resolvedUrl("PairDevicePage.qml");
                    obj.accepted.connect(unpairAccepted);
                } else {
                    app.pages.push(Qt.resolvedUrl("PairDevicePage.qml"));
                }
            }
        }
        PageMenuItemPL {
            text: qsTr("Install File")
            onClicked: app.pages.push(Qt.resolvedUrl("BipFirmwarePage.qml"))
        }
        PageMenuItemPL {
            text: qsTr("Settings")
            onClicked: app.pages.push(Qt.resolvedUrl("Settings-menu.qml"))
        }
        PageMenuItemPL {
            text: qsTr("Data Graphs")
            onClicked: app.pages.push(Qt.resolvedUrl("AnalysisPage.qml"))
        }
        PageMenuItemPL {
            visible: AmazfishConfig.pairedAddress
            enabled: !_connecting
            text: _disconnected ? qsTr("Connect to watch") : qsTr("Disconnect from watch")
            onClicked: {
                if (_disconnected) {
                    DaemonInterfaceInstance.connectToDevice(AmazfishConfig.pairedAddress);
                } else {
                    DaemonInterfaceInstance.disconnect();
                }
            }
        }
    }

    Column {
        id: column
        spacing: styler.themePaddingLarge
        anchors.top: parent.top
        width: parent.width
        anchors.margins: styler.themePaddingMedium

        RowLayout {
            id: rowUpdateOperation
            height: styler.themeItemSizeSmall
            width: parent.width
            visible: DaemonInterfaceInstance.operationRunning
            LabelPL {
                id: lblLastMessage
                text: _lastMessage
                color: styler.themeSecondaryHighlightColor
                font.pixelSize: styler.themeFontSizeMedium
                truncMode: truncModes.fade
                Layout.fillWidth: true
                width: parent.width *0.6
            }
            LabelPL {
                id: lblProgress
                x: 10
                anchors.leftMargin: 5
                horizontalAlignment: Text.AlignLeft
                color: styler.themeSecondaryHighlightColor
                font.pixelSize: styler.themeFontSizeMedium
                text: _percentText
            }

            BusyIndicatorSmallPL {
                y: 2
                running: DaemonInterfaceInstance.operationRunning
                Layout.alignment: Qt.AlignRight
                anchors.rightMargin: 2
                height: parent.height - 4
            }
        }

        RowLayout {
            height: styler.themeItemSizeSmall
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: styler.themePaddingLarge
            anchors.rightMargin: styler.themePaddingLarge

            LabelPL {
                id: pairedNameLabel
                text: AmazfishConfig.pairedName
                color: styler.themeSecondaryHighlightColor
                font.pixelSize: styler.themeFontSizeLarge
                truncMode: truncModes.fade
                Layout.fillWidth: true

            }

            IconPL {
                iconName: styler.iconBluetooth
                iconHeight: styler.themeIconSizeMedium
                visible: _connected || _authenticated || _connecting
                BusyIndicatorSmallPL {
                    visible: _connecting
                    running: visible
                    anchors.centerIn: parent
                }
            }

            IconPL {
                iconName: styler.iconWatch
                iconHeight: styler.themeIconSizeMedium
                visible: _authenticated || _connected
                BusyIndicatorSmallPL {
                    visible: _connected
                    running: visible
                    anchors.centerIn: parent
                }
            }

            IconPL {
                id: btryImage
                iconName: styler.iconBattery
                iconHeight: styler.themeIconSizeMedium
                visible: _authenticated
            }

            LabelPL {
                id: btryPercent
                visible: _authenticated
                font.pixelSize: styler.themeFontSizeMedium
                width: styler.themeIconSizeMedium
                text: qsTr("%1%").arg(_InfoBatteryPercent)
            }
        }

        SectionHeaderPL {
            text: qsTr("Steps")
            visible: supportsFeature(Amazfish.FEATURE_STEPS)
        }

        // steps
        IconPL {
            id: imgSteps
            anchors.left: parent.left
            anchors.leftMargin: styler.themePaddingLarge
            iconName: styler.iconSteps
            height: styler.themeIconSizeMedium
            width: height
            visible: supportsFeature(Amazfish.FEATURE_STEPS)
        }

        PercentCircle {
            id: stpsCircle
            visible: supportsFeature(Amazfish.FEATURE_STEPS)
            anchors.horizontalCenter: parent.horizontalCenter
            size: parent.width - styler.themeHorizontalPageMargin * 4
            percent: _InfoSteps ? _InfoSteps / AmazfishConfig.profileFitnessGoal : 0.06
            widthRatio: 0.08

            Item {
                anchors.centerIn: parent
                height: lblSteps.height + lblGoal.height + styler.paddingSmall
                width: Math.max(lblSteps.width, lblGoal.width)

                LabelPL {
                    id: lblSteps
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: styler.themeHighlightColor
                    font.pixelSize: styler.themeFontSizeExtraLarge
                    verticalAlignment: Text.AlignVCenter
                    text: _InfoSteps.toLocaleString()
                }

                LabelPL {
                    id: lblGoal
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: lblSteps.bottom
                        topMargin: styler.themePaddingSmall
                    }
                    color: styler.themeSecondaryHighlightColor
                    font.pixelSize: styler.themeFontSizeLarge
                    verticalAlignment: Text.AlignVCenter
                    text: AmazfishConfig.profileFitnessGoal.toLocaleString()
                }
            }
            Component.onCompleted: {
                if (_connected) {
                    _InfoSteps = parseInt(DaemonInterfaceInstance.information(Amazfish.INFO_STEPS), 10) || 0;
                }
            }
        }

        SectionHeaderPL {
            text: qsTr("Heartrate")
            visible: supportsFeature(Amazfish.FEATURE_HRM)
        }

        //Heartrate
        RowLayout {
            anchors.left: parent.left
            anchors.leftMargin: styler.themePaddingLarge
            anchors.right: parent.right
            anchors.rightMargin: styler.themePaddingLarge
            spacing: styler.themePaddingLarge
            width: parent.width
            visible: supportsFeature(Amazfish.FEATURE_HRM)

            IconPL {
                id: imgHeartrate
                iconName: styler.iconHeartrate
                width: styler.themeIconSizeMedium
                height: width
            }
            LabelPL {
                id: lblHeartrate
                color: styler.themePrimaryColor
                font.pixelSize: styler.themeFontSizeLarge
                height: styler.iconSizeMedium
                verticalAlignment: Text.AlignVCenter
                text: qsTr("%1 bpm").arg(_InfoHeartrate)
            }

            Item {
                Layout.fillWidth: true
            }

            IconButtonPL {
                id: btnHR
                iconName: styler.iconRefresh
                iconHeight: styler.themeIconSizeMedium
                iconWidth: iconHeight
                onClicked: {
                    DaemonInterfaceInstance.requestManualHeartrate();
                }
            }
        }

        SectionHeaderPL {
            text: qsTr("Service")
            visible: btnSystemdEnable.visible
        }

        ButtonPL {
            id: btnSystemdEnable
            text: qsTr("Enable on boot")
            visible: serviceEnabledState == false && (ENABLE_SYSTEMD === "YES")
            anchors.horizontalCenter: parent.horizontalCenter

            onClicked: {
                systemdManager.enableService();
            }
        }

        Timer {
            id: tmrStartup
            running: false
            repeat: false
            interval: 500
            onTriggered: {
                console.log("Start timer triggered");
                pushAttached(Qt.resolvedUrl("StepsPage.qml"))
                if (!AmazfishConfig.profileName) {
                    app.pages.push(Qt.resolvedUrl("Settings-profile.qml"))
                }
            }
        }
    }

    onPageStatusActive: {
        tmrStartup.start();
    }

    Component.onCompleted: {
        if (AmazfishConfig.profileName) {
            _refreshInformation();
        }
        start();
    }

    function start() {
        app.rootPage = page;
    }
}
