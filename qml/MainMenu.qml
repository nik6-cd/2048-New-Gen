import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"

Rectangle {
    id: menuRoot
    color: activeTheme.bg

    // Проверка ориентации: портрет (телефон) или ландшафт (ПК)
    readonly property bool isPortrait: height > width
    // Базовая единица для масштабирования текста и отступов
    readonly property real baseUnit: Math.min(width, height)

    ColumnLayout {
        // Растягиваем лейаут на всё доступное пространство
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.preferredHeight: isPortrait ? parent.height * 0.24 : parent.height * 0.30
        }

        // --- ЗАГОЛОВОК ---
        Item {
            Layout.preferredHeight: parent.height * 0.16
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: "2048: New Gen"
                color: activeTheme.text
                font.pixelSize: baseUnit * 0.12
                font.family: caveatFont.name
                font.bold: true
                anchors.centerIn: parent
                // Центрируем внутри лейаута

            }
        }

        Item {
            Layout.preferredHeight: isPortrait ? parent.height * 0.28 : parent.height * 0.1
        }

        // --- КНОПКА PLAY ---
        CustomButton {
            // Используем тернарный оператор для смены текста
            text: (gameLogic.isGameActive) ? "Continue" : "Play"
            textColor: activeTheme.text
            font.family: "Montserrat"
            font.pixelSize: Math.max(baseUnit * 0.05, 24)
            bodyColor: activeTheme.bt

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: isPortrait ? parent.width * 0.85 : Math.min(parent.width * 0.6, 650)
            Layout.preferredHeight: parent.height * 0.12

            onClicked: {
                if (typeof stackView !== "undefined") {
                    stackView.push("qrc:/qt/qml/GameLogic/qml/GameView.qml");
                }
            }
        }

        Item {
            Layout.preferredHeight: parent.height * 0.02
        }

        // --- КНОПКА SETTINGS ---
        CustomButton {
            text: "Settings"
            textColor: activeTheme.text
            font.family: "Montserrat"
            font.pixelSize: Math.max(baseUnit * 0.04, 18)
            bodyColor: activeTheme.bt2

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: isPortrait ? parent.width * 0.75 : Math.min(parent.width * 0.45, 500)
            Layout.preferredHeight: parent.height * 0.06

            onClicked: {
                if (typeof stackView !== "undefined") {
                    stackView.push("qrc:/qt/qml/GameLogic/qml/Settings.qml");
                }
            }
        }

        Item {
            Layout.preferredHeight: parent.height * 0.02
        }

        CustomButton {
            text: "Exit"
            textColor: activeTheme.text
            font.family: "Montserrat"
            font.pixelSize: Math.max(baseUnit * 0.04, 18)
            bodyColor: activeTheme.bt3

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: isPortrait ? parent.width * 0.75 : Math.min(parent.width * 0.45, 500)
            Layout.preferredHeight: parent.height * 0.06

            onClicked: {
                Qt.quit();
            }
        }
        Item {
            Layout.preferredHeight: isPortrait ? parent.height * 0.04 : parent.height * 0.16
        }
    }
}
