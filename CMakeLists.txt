cmake_minimum_required(VERSION 3.16)

project(game2048 VERSION 0.1 LANGUAGES CXX)

# Налаштування стандарту C++
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Пошук необхідних компонентів Qt 6
find_package(Qt6 REQUIRED COMPONENTS Quick Multimedia QuickControls2)

# Стандартне налаштування структури проєкту для Qt 6
qt_standard_project_setup(REQUIRES 6.10)

# Оголошення виконуваного файлу додатка
qt_add_executable(appgame2048
    main.cpp
)

# Створення та налаштування QML-модуля
qt_add_qml_module(appgame2048
    URI GameLogic
    VERSION 1.0

    # Файли інтерфейсу QML
    QML_FILES
        qml/main.qml
        qml/MainMenu.qml
        qml/Settings.qml
        qml/GameView.qml
        qml/GameOverView.qml
        qml/components/CustomButton.qml

    # Статичні ресурси додатка (шрифти, звуки, зображення)
    RESOURCES
        resources/fonts/Caveat-Regular.ttf
        resources/sounds/backgroundLoop.wav
        resources/sounds/boomTile.wav
        resources/sounds/swipe.wav
        resources/assets/circle.png

    # Вихідні файли C++ (ігрова логіка)
    SOURCES
        cpp/gameengine.h
        cpp/gameengine.cpp
)

# Налаштування специфічних властивостей таргета для macOS/iOS та Windows
set_target_properties(appgame2048 PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE       # Збирання у вигляді бандла для macOS/iOS
    WIN32_EXECUTABLE TRUE   # Приховує консольне вікно під час запуску на Windows
)

# Лінкування необхідних модулів Qt 6 до нашого додатка
target_link_libraries(appgame2048
    PRIVATE Qt6::Quick Qt6::Multimedia Qt6::QuickControls2
)

# Правила розгортання та інсталяції додатка
install(TARGETS appgame2048
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)