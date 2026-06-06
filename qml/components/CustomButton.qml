import QtQuick 2.15
import QtQuick.Controls 2.15



Button {
    id: control
    focusPolicy: Qt.NoFocus
    hoverEnabled: true

    // Свойства, которые можно будет менять снаружи
    property color bodyColor: "#16a085"
    property color pressedColor: "#1abc9c"
    property color textColor: "white"
    property int borderRadius: 10

    // 1. СТИЛЬ ТЕКСТА
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.textColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight

        // Добавляем небольшую тень для объема (по желанию)
        style: Text.Outline
        styleColor: "black"
    }

    // 2. СТИЛЬ ФОНА (Тот самый "CSS")
    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 50

        // Логика: приоритет у нажатия, потом наведение, потом покой
        color: control.pressed ? control.pressedColor :
               control.hovered ? Qt.lighter(control.bodyColor, 1.2) : // +20% яркости
               control.bodyColor

        radius: control.borderRadius

        // Чтобы переход был мягким, а не дерганым:
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
}