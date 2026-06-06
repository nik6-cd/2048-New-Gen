import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components" // чтобы подтянулись твои CustomButton

Rectangle {
    id: gameOverRoot
    color: activeTheme.bg // Твой основной темный фон

    // Эти свойства мы передаем при push из StackView
    property int finalScore: 0
    property int bestScore: 0

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 30
        width: parent.width * 0.8

        // Заголовок
        Text {
            text: "GAME OVER"
            color: activeTheme.text // Желтый акцентный цвет
            font.pixelSize: parent.width * 0.15
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // Блок с результатами
        ColumnLayout {
            spacing: 10
            Layout.alignment: Qt.AlignHCenter

            Text {
                text: "SCORE: " + finalScore
                color: activeTheme.text
                font.pixelSize: 24
                font.family: "Montserrat"
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "BEST: " + bestScore
                color: activeTheme.text
                font.pixelSize: 18
                font.family: "Montserrat"
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // Кнопки управления
        ColumnLayout {
            spacing: 15
            Layout.topMargin: 20
            Layout.alignment: Qt.AlignHCenter

            CustomButton {
                text: "Try Again"
                Layout.preferredWidth: 200
                Layout.preferredHeight: 50
                bodyColor: activeTheme.bt
                textColor: activeTheme.text
                onClicked: {
                    gameLogic.restart() // Сбрасываем логику
                    stackView.pop()    // Возвращаемся в игру
                }
            }

            CustomButton {
                text: "Main Menu"
                Layout.preferredWidth: 200
                Layout.preferredHeight: 50
                bodyColor: activeTheme.bt2
                textColor: activeTheme.text
                onClicked: {
                    // Возвращаемся к самому первому экрану (меню)
                    stackView.pop(null)
                }
            }
        }
    }

    // Анимация появления (чтобы не резко вылетало)
    opacity: 0
    NumberAnimation on opacity {
        to: 1
        duration: 500
    }
}