#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext> // <--- Добавь этот инклюд
#include <QQuickStyle>
#include "cpp/gameengine.h" // <--- И этот

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQuickStyle::setStyle("Basic");

    // Создаем экземпляр нашей игры
    GameEngine game;

    QQmlApplicationEngine engine;

    // Прокидываем объект game в QML под именем "gameLogic"
    engine.rootContext()->setContextProperty("gameLogic", &game);

    const QUrl url(u"qrc:/qt/qml/GameLogic/qml/main.qml"_s);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
                         if (!obj && url == objUrl)
                             QCoreApplication::exit(-1);
                     }, Qt::QueuedConnection);

    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts);
    engine.load(url);

    return app.exec();
}