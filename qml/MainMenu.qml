import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"

Rectangle {
    id: menuRoot
    color: activeTheme.bg

    // Перевірка орієнтації екрана: портретна (смартфон) або ландшафтна (ПК)
    readonly property bool isPortrait: height > width

    // Базова одиниця для адаптивного масштабування тексту та відступів
    readonly property real baseUnit: Math.min(width, height)

    ColumnLayout {
        // Розтягуємо компонувальник (layout) на весь доступний простір вікна
        anchors.fill: parent
        spacing: 0

        // Верхній порожній відступ (простір над заголовком)
        Item {
            Layout.preferredHeight: isPortrait ? parent.height * 0.24 : parent.height * 0.30
        }

        // --- ЗАГОЛОВОК ГРИ ---
        Item {
            Layout.preferredHeight: parent.height * 0.16
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: "2048: New Gen"
                color: activeTheme.text
                font.pixelSize: baseUnit * 0.12
                font.family: caveatFont.name
                font.bold: true
                anchors.centerIn: parent // Центруємо текст всередині контейнера
            }
        }

        // Проміжний порожній відступ між заголовком та кнопками
        Item {
            Layout.preferredHeight: isPortrait ? parent.height * 0.28 : parent.height * 0.1
        }

        // --- КНОПКА PLAY / CONTINUE ---
        CustomButton {
            // Динамічна зміна тексту залежно від стану ігрової сесії
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
                    stackView.push("qrc:/qt/qml/GameLogic/qml/GameView.qml"); // Перехід до екрана гри
                }
            }
        }

        Item {
            Layout.preferredHeight: parent.height * 0.02
        }

        // --- КНОПКА НАЛАШТУВАНЬ (SETTINGS) ---
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
                    stackView.push("qrc:/qt/qml/GameLogic/qml/Settings.qml"); // Перехід до налаштувань
                }
            }
        }

        Item {
            Layout.preferredHeight: parent.height * 0.02
        }

        // --- КНОПКА ВИХОДУ (EXIT) ---
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
                Qt.quit(); // Завершення роботи програми
            }
        }

        // Нижній порожній відступ для балансу композиції меню
        Item {
            Layout.preferredHeight: isPortrait ? parent.height * 0.04 : parent.height * 0.16
        }
    }
}