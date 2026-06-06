import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Qt.labs.settings
import QtMultimedia

Window {
    id: mainWindow

    visible: true

    width: screen.width / 2
    height: screen.height / 2
    minimumWidth: screen.width / 3
    minimumHeight: 500



    title: "2048 Special Edition"

    // Themes
    readonly property var themes: [
        { // 0: Forest
            "bg": "#1E1E26",
            "bt" : "#729969",
            "bt2" : "#A1C0C2",
            "bt3" : "#506263",
            "text" : "#E6E7EB"
        },
        { // 1: Spring
            "bg": "#ce4670",
            "bt" : "#eca3bb",
            "bt2" : "#9ec23a",
            "bt3" : "#76bbfa",
            "text" : "#ddedf5"
        },
        { // 2: Coffee
            "bg": "#795A46",
            "bt" : "#B79479",
            "bt2" : "#CDC3BE",
            "bt3" : "#EBEBEB",
            "text" : "#F3F2EE"
        }
    ]

    readonly property var activeTheme: themes[appSettings.themeIndex]

    function toggleFullscreen() {
        if (mainWindow.visibility === Window.FullScreen) {
            mainWindow.visibility = Window.Windowed;
        } else {
            mainWindow.visibility = Window.FullScreen;
        }
    }

    Settings {
            id: appSettings
            fileName: "setti"
            property bool soundEnabled: true
            property real fullVolume: 1
            property real actionVolume: 0.5
            property real backVolume: 0.5
            property int themeIndex: 0

            property alias winWidth: mainWindow.width
            property alias winHeight: mainWindow.height

            property int bestScore: 0
        }

    FontLoader {
        id: caveatFont
        source: "qrc:/qt/qml/GameLogic/resources/fonts/Caveat-Regular.ttf"
    }

    SoundEffect {
        id: moveSound
        source: "qrc:/qt/qml/GameLogic/resources/sounds/swipe.wav"
        volume: appSettings.soundEnabled ? appSettings.fullVolume*appSettings.actionVolume : 0
    }

    SoundEffect {
        id: explosionSound
        source: "qrc:/qt/qml/GameLogic/resources/sounds/boomTile.wav"
        volume: appSettings.soundEnabled ? appSettings.fullVolume*appSettings.actionVolume : 0
    }

    MediaPlayer {
        id: bgMusic
        source: "qrc:/qt/qml/GameLogic/resources/sounds/backgroundLoop.wav"
        loops: MediaPlayer.Infinite

            // Привязываем выход звука
            audioOutput: AudioOutput {
                id: audioDevice
                volume: appSettings.soundEnabled ? appSettings.fullVolume*appSettings.backVolume : 0
            }

        Component.onCompleted: play()

    }

    Component.onCompleted: if(screen.width < screen.height) toggleFullscreen();

    StackView {
        id: stackView
        anchors.fill: parent
        background: Rectangle {
                color: activeTheme.bg
            }
        initialItem: "qrc:/qt/qml/GameLogic/qml/MainMenu.qml"
    }
}
