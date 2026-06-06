import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Particles 2.15
import "components"

Rectangle {
    id: gameViewRoot
    color: activeTheme.bg
    focus: true

    Component.onCompleted: {
        gameViewRoot.forceActiveFocus();
        gameLogic.bestScore = appSettings.bestScore;
    }

    Timer {
        id: gameOverTimer
        interval: 800
        onTriggered: {
            stackView.push("qrc:/qt/qml/GameLogic/qml/GameOverView.qml", {
                "finalScore": gameLogic.score,
                "bestScore": gameLogic.bestScore
            });
            gameLogic.restart();
        }
    }

    Connections {
        target: gameLogic
        function onBestScoreChanged() {
            appSettings.bestScore = gameLogic.bestScore;
        }
        function onGameOver() {
            gameOverTimer.start();
        }
        function onBombExploded() {
            explosionSound.play();
            explosionEmitter.x = tilesContainer.width / 2 // или координаты бомбы
            explosionEmitter.y = tilesContainer.height / 2
            explosionEmitter.pulse(150); // Выпускает частицы в течение 300мс
        }
        function onTileMoved() {
            moveSound.play();
        }
    }

    readonly property bool isPortrait: height > width
    readonly property real baseUnit: Math.min(width, height)
    readonly property real boardSize: isPortrait ? width * 0.9 : height * 0.8

    ColumnLayout {
        anchors.fill: parent

        // --- ВЕРХНЯЯ ПАНЕЛЬ ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: baseUnit * 0.1

            Item {
                Layout.preferredWidth: gameViewRoot.width * 0.01
            }

            CustomButton {
                text: "←"
                Layout.preferredWidth: baseUnit * 0.12
                Layout.preferredHeight: baseUnit * 0.1
                bodyColor: activeTheme.bt2
                onClicked: if (typeof stackView !== "undefined")
                    stackView.pop()
            }

            Item {
                Layout.preferredWidth: gameViewRoot.width * 0.01
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "SCORE"
                    color: activeTheme.text
                    font.pixelSize: baseUnit * 0.03
                    font.family: "Montserrat"
                }
                Text {
                    text: gameLogic.score.toString()
                    color: activeTheme.text
                    font.pixelSize: baseUnit * 0.06
                    font.bold: true
                }
            }

            Item {
                Layout.fillWidth: true
            }

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignRight
                Text {
                    text: "BEST"
                    color: activeTheme.text
                    font.pixelSize: baseUnit * 0.03
                    Layout.alignment: Qt.AlignRight
                }
                Text {
                    text: gameLogic.bestScore.toString()
                    color: activeTheme.text
                    font.pixelSize: baseUnit * 0.05
                    font.bold: true
                }
            }

            Item {
                Layout.preferredWidth: gameViewRoot.width * 0.01
            }
        }

        // --- ИГРОВОЕ ПОЛЕ ---
        Rectangle {
            id: backgroundBoard
            Layout.preferredHeight: baseUnit * 0.7
            Layout.preferredWidth: baseUnit * 0.7
            Layout.alignment: Qt.AlignHCenter
            color: Qt.lighter(activeTheme.bg, 0.8)
            radius: 10

            readonly property real tileSpacing: backgroundBoard.width * 0.025
            readonly property real tileSize: (backgroundBoard.width - (tileSpacing * 5)) / 4

            Grid {
                id: backgroundGrid
                anchors.centerIn: parent
                columns: 4
                rows: 4
                spacing: backgroundBoard.tileSpacing

                Repeater {
                    model: 16
                    Rectangle {
                        width: backgroundBoard.tileSize
                        height: width
                        color: Qt.lighter(activeTheme.bg, 1.4)
                        radius: 5
                    }
                }
            }
            Item {
                id: tilesContainer
                anchors.fill: backgroundGrid

                ParticleSystem {
                    id: explosionSystem
                    anchors.fill: parent
                }

                Emitter {
                    id: explosionEmitter
                    system: explosionSystem
                    enabled: false // Включаем только при взрыве
                    emitRate: 1000
                    lifeSpan: 500
                    size: 20
                    sizeVariation: 10
                    velocity: AngleDirection { angleVariation: 360; magnitude: 200 }
                }

                ImageParticle {
                    system: explosionSystem
                    source: "qrc:/qt/qml/GameLogic/resources/assets/circle.png" // Создайте маленький белый кружок или звездочку
                    color: "#FF4500" // Цвет огня
                }


                Repeater {
                    // gameLogic теперь является полноценной моделью данных
                    model: gameLogic

                    Rectangle {
                        id: tileDelegate
                        width: backgroundBoard.tileSize
                        height: width
                        radius: 5

                        // Координаты теперь ЖЕСТКО привязаны к ролям row и col из C++
                        x: col * (width + backgroundBoard.tileSpacing)
                        y: row * (height + backgroundBoard.tileSpacing)

                        // Стартуем с 0 для анимации "вылупления"
                        scale: 0
                        opacity: 0

                        // Как только компонент создан, привязываем значения к состоянию dying
                        Component.onCompleted: {
                            scale = Qt.binding(function () {
                                return dying ? 0.6 : 1.0;
                            });
                            opacity = Qt.binding(function () {
                                return dying ? 0.0 : 1.0;
                            });
                        }

                        // --- МАГИЯ АНИМАЦИЙ ЗДЕСЬ ---
                        Behavior on x {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutQuad
                            }
                        }
                        Behavior on y {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutQuad
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutBack
                            }
                        } // Эффект пружинки

                        // Покраска
                        color: {
                            if (t === 2)
                                return "#E74C3C"; // Бомба
                            if (t === 3)
                                return "#74B9FF"; // Лед
                            return v === 2 ? "#EEE4DA" : v === 4 ? "#EDE0C8" : v === 8 ? "#F2B179" : v === 16 ? "#F59563" : v === 32 ? "#F67C5F" : v === 64 ? "#F65E3B" : v >= 128 ? "#EDCF72" : "#3A3A45";
                        }

                        Text {
                            anchors.centerIn: parent
                            text: v.toString()
                            color: (t === 2 || t === 3 || v > 4) ? "#F9F6F2" : "#776E65"
                            font.pixelSize: parent.height * 0.4
                            font.bold: true
                            fontSizeMode: Text.Fit
                            minimumPixelSize: 10
                        }

                        // Таймер для бомбы или прочность для льда
                        Text {
                            visible: t === 2 || t === 3 // Показываем и для бомбы, и для льда
                            // Для бомбы показываем часики, для льда - снежинку
                            text: t === 2 ? "⏱" + timer : "❄️" + timer

                            color: "#FFFFFF"
                            font.pixelSize: parent.height * 0.18
                            font.bold: true
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 4
                        }
                    }
                }
            }
        }

        // --- НИЖНЯЯ ПАНЕЛЬ ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: boardSize
            spacing: baseUnit * 0.05

            CustomButton {
                text: "Restart"
                Layout.alignment: Qt.AlignHCenter

                Layout.preferredWidth: tilesContainer.width
                Layout.preferredHeight: baseUnit * 0.1
                bodyColor: activeTheme.bt
                textColor: activeTheme.text
                font.pixelSize: baseUnit * 0.04
                onClicked: gameLogic.restart()
            }
        }
    }

    Keys.onPressed: event => {
        switch (event.key) {
        case Qt.Key_Left:

            gameLogic.moveLeft();
            break;
        case Qt.Key_Right:

            gameLogic.moveRight();
            break;
        case Qt.Key_Up:

            gameLogic.moveUp();
            break;
        case Qt.Key_Down:

            gameLogic.moveDown();
            break;
        }
    }
}
