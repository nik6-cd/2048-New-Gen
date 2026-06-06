import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components" // Підключення кастомних компонентів

Rectangle {
    id: gameOverRoot
    color: activeTheme.bg // Основний темний фон додатка

    // Властивості, що передаються під час push-переходу зі StackView
    property int finalScore: 0
    property int bestScore: 0

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 30
        width: parent.width * 0.8

        // Головний заголовок екрана
        Text {
            text: "GAME OVER"
            color: activeTheme.text // Акцентний колір тексту теми
            font.pixelSize: parent.width * 0.15
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        // Блок відображення результатів гравця
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

        // Кнопки керування навігацією
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
                    gameLogic.restart() // Скидання ігрової логіки до початкового стану
                    stackView.pop()     // Повернення назад до екрана гри
                }
            }

            CustomButton {
                text: "Main Menu"
                Layout.preferredWidth: 200
                Layout.preferredHeight: 50
                bodyColor: activeTheme.bt2
                textColor: activeTheme.text
                onClicked: {
                    // Очищення стека та повернення до найпершого екрана (головного меню)
                    stackView.pop(null)
                }
            }
        }
    }

    // Анімація плавної появи екрана (Fade-in ефект)
    opacity: 0
    NumberAnimation on opacity {
        to: 1
        duration: 500
    }
}