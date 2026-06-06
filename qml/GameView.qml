import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Particles 2.15
import "components"

Rectangle {
    id: gameViewRoot
    color: activeTheme.bg
    focus: true

    // Ініціалізація після повного завантаження компонента
    Component.onCompleted: {
        gameViewRoot.forceActiveFocus(); // Захоплюємо фокус клавіатури
        gameLogic.bestScore = appSettings.bestScore; // Завантажуємо рекорд із налаштувань
    }

    // Таймер затримки перед переходом на екран Game Over
    Timer {
        id: gameOverTimer
        interval: 800
        onTriggered: {
            stackView.push("qrc:/qt/qml/GameLogic/qml/GameOverView.qml", {
                "finalScore": gameLogic.score,
                "bestScore": gameLogic.bestScore
            });
            gameLogic.restart(); // Скидаємо поле після переходу
        }
    }

    // Відстеження сигналів із C++ ядра (gameLogic)
    Connections {
        target: gameLogic

        function onBestScoreChanged() {
            appSettings.bestScore = gameLogic.bestScore; // Зберігаємо новий рекорд
        }
        function onGameOver() {
            gameOverTimer.start(); // Запуск таймера завершення гри
        }
        function onBombExploded() {
            explosionSound.play();
            // Центрування емітера частинок на ігровому полі
            explosionEmitter.x = tilesContainer.width / 2
            explosionEmitter.y = tilesContainer.height / 2
            explosionEmitter.pulse(150); // Генеруємо спалах частинок протягом 150 мс
        }
        function onTileMoved() {
            moveSound.play(); // Звук успішного зсування плиток
        }
    }

    // Розрахунок адаптивної геометрії інтерфейсу
    readonly property bool isPortrait: height > width
    readonly property real baseUnit: Math.min(width, height)
    readonly property real boardSize: isPortrait ? width * 0.9 : height * 0.8

    ColumnLayout {
        anchors.fill: parent

        // --- ВЕРХНЯ ПАНЕЛЬ (Рахунок та Керування) ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: baseUnit * 0.1

            Item { Layout.preferredWidth: gameViewRoot.width * 0.01 }

            CustomButton {
                text: "←"
                Layout.preferredWidth: baseUnit * 0.12
                Layout.preferredHeight: baseUnit * 0.1
                bodyColor: activeTheme.bt2
                onClicked: if (typeof stackView !== "undefined") stackView.pop()
            }

            Item { Layout.preferredWidth: gameViewRoot.width * 0.01 }

            // Поточні очки
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

            Item { Layout.fillWidth: true }

            // Найкращий результат
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

            Item { Layout.preferredWidth: gameViewRoot.width * 0.01 }
        }

        // --- ІГРОВЕ ПОЛЕ ---
        Rectangle {
            id: backgroundBoard
            Layout.preferredHeight: baseUnit * 0.7
            Layout.preferredWidth: baseUnit * 0.7
            Layout.alignment: Qt.AlignHCenter
            color: Qt.lighter(activeTheme.bg, 0.8)
            radius: 10

            // Обчислення динамічного розміру плиток та відступів
            readonly property real tileSpacing: backgroundBoard.width * 0.025
            readonly property real tileSize: (backgroundBoard.width - (tileSpacing * 5)) / 4

            // Статична задня сітка (16 порожніх клітинок)
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

            // Контейнер для активних плиток та ефектів
            Item {
                id: tilesContainer
                anchors.fill: backgroundGrid

                // Система частинок для ефекту вибуху бомби
                ParticleSystem {
                    id: explosionSystem
                    anchors.fill: parent
                }

                Emitter {
                    id: explosionEmitter
                    system: explosionSystem
                    enabled: false
                    emitRate: 1000
                    lifeSpan: 500
                    size: 20
                    sizeVariation: 10
                    velocity: AngleDirection { angleVariation: 360; magnitude: 200 }
                }

                ImageParticle {
                    system: explosionSystem
                    source: "qrc:/qt/qml/GameLogic/resources/assets/circle.png"
                    color: "#FF4500" // Вогняний колір частинок
                }

                // Відображення активних плиток на основі C++ моделі
                Repeater {
                    model: gameLogic

                    Rectangle {
                        id: tileDelegate
                        width: backgroundBoard.tileSize
                        height: width
                        radius: 5

                        // Розрахунок позиції через C++ ролі 'row' та 'col'
                        x: col * (width + backgroundBoard.tileSpacing)
                        y: row * (height + backgroundBoard.tileSpacing)

                        // Початковий стан для ефекту появи (плавне масштабування)
                        scale: 0
                        opacity: 0

                        // Динамічне зв'язування станів згортання/видалення плитки (dying)
                        Component.onCompleted: {
                            scale = Qt.binding(function () {
                                return dying ? 0.6 : 1.0;
                            });
                            opacity = Qt.binding(function () {
                                return dying ? 0.0 : 1.0;
                            });
                        }

                        // --- АНІМАЦІЇ ПЕРЕМІЩЕННЯ ТА СТАНІВ ---
                        Behavior on x {
                            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                        }
                        Behavior on y {
                            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                        Behavior on scale {
                            // Ефект "пружини" (OutBack) під час появи нової плитки
                            NumberAnimation { duration: 250; easing.type: Easing.OutBack }
                        }

                        // Стилізація кольору плитки залежно від її типу та номіналу
                        color: {
                            if (t === 2) return "#E74C3C"; // Бомба
                            if (t === 3) return "#74B9FF"; // Крига
                            return v === 2 ? "#EEE4DA" : v === 4 ? "#EDE0C8" : v === 8 ? "#F2B179" : v === 16 ? "#F59563" : v === 32 ? "#F67C5F" : v === 64 ? "#F65E3B" : v >= 128 ? "#EDCF72" : "#3A3A45";
                        }

                        // Відображення номіналу плитки
                        Text {
                            anchors.centerIn: parent
                            text: v.toString()
                            color: (t === 2 || t === 3 || v > 4) ? "#F9F6F2" : "#776E65"
                            font.pixelSize: parent.height * 0.4
                            font.bold: true
                            fontSizeMode: Text.Fit
                            minimumPixelSize: 10
                        }

                        // Іконка та значення таймера для спец-плиток (Бомба/Крига)
                        Text {
                            visible: t === 2 || t === 3
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

        // --- НИЖНЯ ПАНЕЛЬ (Кнопка перезапуску) ---
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

    // Обробка подій натискання клавіш стрілок клавіатури
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