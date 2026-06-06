import QtQuick 2.15
import QtQuick.Controls 2.15

Button {
    id: control
    focusPolicy: Qt.NoFocus
    hoverEnabled: true

    // Зовнішні властивості для кастомізації кнопки
    property color bodyColor: "#16a085"
    property color pressedColor: "#1abc9c"
    property color textColor: "white"
    property int borderRadius: 10

    // 1. Стилізація тексту кнопки
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight

        // Легке обведення тексту для читабельності та об'єму
        style: Text.Outline
        styleColor: "black"
    }

    // 2. Стилізація фону (аналог CSS)
    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 50

        // Логіка кольору: натискання -> наведення курсора (+20% яскравості) -> спокій
        color: control.pressed ? control.pressedColor :
               control.hovered ? Qt.lighter(control.bodyColor, 1.2) :
               control.bodyColor

        radius: control.borderRadius

        // Анімація для плавного переходу кольору стану кнопки
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
}