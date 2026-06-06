import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"

Rectangle {
    id: settingsRoot
    color: activeTheme.bg // Глибокий темний фон додатка

    // Перевірка орієнтації екрана: портретна (смартфон) або ландшафтна (ПК)
    readonly property bool isPortrait: height > width
    // Базова одиниця для адаптивного масштабування тексту та відступів
    readonly property real baseUnit: Math.min(width, height)

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.8
        spacing: 20

        Text {
            text: "Settings"
            color: activeTheme.text
            font.pixelSize: 32
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // --- БЛОК КЕРУВАННЯ ЗВУКОМ ---
        RowLayout {
            Text {
                text: "Sound"
                color: activeTheme.text
                Layout.fillWidth: true
            }
            Switch {
                checked: appSettings.soundEnabled
                onPositionChanged: appSettings.soundEnabled = checked
            }
        }

        // --- ЗАГАЛЬНА ГУЧНІСТЬ (Master Volume) ---
        ColumnLayout {
            Text {
                text: "Master Volume: " + Math.round(volumeFullSlider.value * 100) + "%"
                color: activeTheme.text
            }
            Slider {
                id: volumeFullSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                value: appSettings.fullVolume
                onMoved: appSettings.fullVolume = value
            }
        }

        // --- ГУЧНІСТЬ ЕФЕКТІВ (Action Volume) ---
        ColumnLayout {
            Text {
                text: "Action Volume: " + Math.round(volumeActiveSlider.value * 100) + "%"
                color: activeTheme.text
            }
            Slider {
                id: volumeActiveSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                value: appSettings.actionVolume
                onMoved: appSettings.actionVolume = value
            }
        }

        // --- ГУЧНІСТЬ МУЗИКИ (Music Volume) ---
        ColumnLayout {
            Text {
                text: "Music Volume: " + Math.round(volumeBackSlider.value * 100) + "%"
                color: activeTheme.text
            }
            Slider {
                id: volumeBackSlider
                Layout.fillWidth: true
                from: 0
                to: 1
                value: appSettings.backVolume
                onMoved: appSettings.backVolume = value
            }
        }

        // --- ВИБІР ТЕМИ (Кастомізований ComboBox) ---
        ComboBox {
            id: themeSelector
            Layout.fillWidth: true
            Layout.preferredHeight: 45
            model: ["Classic", "Neon", "Industrial"]
            currentIndex: appSettings.themeIndex
            onActivated: appSettings.themeIndex = currentIndex

            // 1. Стилізація тексту на самій кнопці вибору
            contentItem: Text {
                leftPadding: 15
                text: themeSelector.displayText
                font.pixelSize: 16
                font.bold: true
                color: activeTheme.text
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            // 2. Фон основної кнопки вибору теми
            background: Rectangle {
                implicitWidth: 120
                implicitHeight: 45
                color: activeTheme.bt2
                border.color: themeSelector.visualFocus ? "#FFFFFF" : "#3A3A45"
                border.width: 1
                radius: 10
            }

            // 3. Стилізація випадного списку елементів (Popup)
            popup: Popup {
                y: themeSelector.height + 5
                width: themeSelector.width
                implicitHeight: contentItem.implicitHeight
                padding: 1

                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: themeSelector.popup.visible ? themeSelector.delegateModel : null
                    currentIndex: themeSelector.highlightedIndex

                    ScrollIndicator.vertical: ScrollIndicator { }
                }

                background: Rectangle {
                    color: activeTheme.bt2
                    border.color: activeTheme.text
                    radius: 10
                }
            }

            // 4. Стилізація елементів усередині випадного списку (рядків)
            delegate: ItemDelegate {
                width: themeSelector.width
                contentItem: Text {
                    text: modelData
                    color: activeTheme.text
                    font.pixelSize: 16
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 15
                }
                background: Rectangle {
                    color: activeTheme.bt3
                    radius: 5
                }
            }
        }

        // --- КНОПКА ПОВЕРНЕННЯ НАЗАД (BACK) ---
        CustomButton {
            text: "Back"
            textColor: activeTheme.text
            font.family: "Montserrat"
            font.pixelSize: Math.max(baseUnit * 0.04, 18)
            bodyColor: activeTheme.bt

            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: isPortrait ? parent.width * 0.85 : Math.min(parent.width * 0.4, 500)
            Layout.preferredHeight: Math.max(parent.height * 0.08, 50)

            onClicked: {
                if (typeof stackView !== "undefined") {
                    // Використовуємо pop() замість push(), щоб коректно вилучити поточний екран зі стека
                    stackView.pop();
                }
            }
        }
    }
}