#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>      // Необхідно для роботи з контекстом QML (setContextProperty)
#include <QQuickStyle>
#include "cpp/gameengine.h" // Підключення заголовка нашого ігрового рушія

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Встановлюємо базовий стиль для Quick Сontrols (швидкий та без зайвих нативних компонентів)
    QQuickStyle::setStyle("Basic");

    // Створюємо екземпляр нашого ігрового рушія
    GameEngine game;

    QQmlApplicationEngine engine;

    // Реєструємо C++ об'єкт 'game' у контексті QML під ім'ям "gameLogic"
    // Тепер методи, слоти та властивості (Q_PROPERTY) доступні в будь-якому QML-файлі
    engine.rootContext()->setContextProperty("gameLogic", &game);

    // Шлях до головного файлу інтерфейсу в ресурсах програми
    const QUrl url(u"qrc:/qt/qml/GameLogic/qml/main.qml"_s);

    // Перевірка коректності завантаження QML-компонентів
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    // Увімкнення спільного використання OpenGL контекстів (корисно для графіки та частинок Particles)
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    engine.load(url);

    return app.exec();
}