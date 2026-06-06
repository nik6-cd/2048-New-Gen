import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt.labs.settings
import QtMultimedia

Window {
    id: mainWindow

    visible: true

    // Налаштування початкових та мінімальних розмірів вікна
    width: screen.width / 2
    height: screen.height / 2
    minimumWidth: screen.width / 3
    minimumHeight: 500

    title: "2048 Special Edition"

    // Колірні теми оформлення додатка
    readonly property var themes: [
        { // 0: Лісова (Forest)
            "bg": "#1E1E26",
            "bt" : "#729969",
            "bt2" : "#A1C0C2",
            "bt3" : "#506263",
            "text" : "#E6E7EB"
        },
        { // 1: Весняна (Spring)
            "bg": "#ce4670",
            "bt" : "#eca3bb",
            "bt2" : "#9ec23a",
            "bt3" : "#76bbfa",
            "text" : "#ddedf5"
        },
        { // 2: Кавова (Coffee)
            "bg": "#795A46",
            "bt" : "#B79479",
            "bt2" : "#CDC3BE",
            "bt3" : "#EBEBEB",
            "text" : "#F3F2EE"
        }
    ]

    // Активна тема, яка автоматично оновлюється при зміні індексу в налаштуваннях
    readonly property var activeTheme: themes[appSettings.themeIndex]

    // Функція перемикання повноекранного режиму вікна
    function toggleFullscreen() {
        if (mainWindow.visibility === Window.FullScreen) {
            mainWindow.visibility = Window.Windowed;
        } else {
            mainWindow.visibility = Window.FullScreen;
        }
    }

    // Збереження користувацьких налаштувань гри у конфігураційний файл
    Settings {
        id: appSettings
        fileName: "setti"
        property bool soundEnabled: true
        property real fullVolume: 1
        property real actionVolume: 0.5
        property real backVolume: 0.5
        property int themeIndex: 0

        // Збереження розмірів вікна між запусками додатка
        property alias winWidth: mainWindow.width
        property alias winHeight: mainWindow.height

        property int bestScore: 0
    }

    // Завантаження кастомного шрифту додатка
    FontLoader {
        id: caveatFont
        source: "qrc:/qt/qml/GameLogic/resources/fonts/Caveat-Regular.ttf"
    }

    // Звуковий ефект для зсування плиток (короткі звуки без затримки)
    SoundEffect {
        id: moveSound
        source: "qrc:/qt/qml/GameLogic/resources/sounds/swipe.wav"
        volume: appSettings.soundEnabled ? appSettings.fullVolume * appSettings.actionVolume : 0
    }

    // Звуковий ефект для вибуху плитки-бомби
    SoundEffect {
        id: explosionSound
        source: "qrc:/qt/qml/GameLogic/resources/sounds/boomTile.wav"
        volume: appSettings.soundEnabled ? appSettings.fullVolume * appSettings.actionVolume : 0
    }

    // Програвач фонової музики (циклічне відтворення)
    MediaPlayer {
        id: bgMusic
        source: "qrc:/qt/qml/GameLogic/resources/sounds/backgroundLoop.wav"
        loops: MediaPlayer.Infinite

        // Прив'язка пристрою виведення звуку та керування гучністю фону
        audioOutput: AudioOutput {
            id: audioDevice
            volume: appSettings.soundEnabled ? appSettings.fullVolume * appSettings.backVolume : 0
        }

        // Автоматичний запуск відтворення після завантаження компонента
        Component.onCompleted: play()
    }

    // Автоматичне увімкнення повноекранного режиму для мобільних пристроїв (портретний екран)
    Component.onCompleted: if(screen.width < screen.height) toggleFullscreen();

    // Менеджер екранів додатка для керування навігацією (меню, гра, налаштування)
    StackView {
        id: stackView
        anchors.fill: parent
        background: Rectangle {
            color: activeTheme.bg
        }
        initialItem: "qrc:/qt/qml/GameLogic/qml/MainMenu.qml" // Стартовий екран головного меню
    }
}