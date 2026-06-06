#ifndef GAMEENGINE_H
#define GAMEENGINE_H

#include <QAbstractListModel>
#include <QList>

// Структура плитки. Зберігає координати та прапорець анімації видалення
struct TileData {
    int id;       // Унікальний ID плитки (для відстеження в QML)
    int r;        // Поточний рядок (row)
    int c;        // Поточна колонка (col)
    int v;        // Номінал плитки (2, 4, 8 і т.д.)
    int t;        // Тип плитки (1 = Звичайна, 2 = Бомба, 3 = Крига, 4 = Вибух)
    int timer;    // Таймер зворотного відліку для бомби
    bool dying;   // Прапорець видалення (для анімації зникнення після злиття/вибуху)
};

class GameEngine : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int score READ score NOTIFY scoreChanged)
    Q_PROPERTY(int bestScore READ bestScore WRITE setBestScore NOTIFY bestScoreChanged)
    Q_PROPERTY(bool isGameActive READ isGameActive NOTIFY isGameActiveChanged)

public:
    // Ролі моделі для зв'язування властивостей плитки з QML
    enum TileRoles {
        ValueRole = Qt::UserRole + 1,
        RowRole,
        ColRole,
        TypeRole,
        TimerRole,
        DyingRole
    };

    bool isGameActive() const { return m_gameStarted; }

    explicit GameEngine(QObject *parent = nullptr);

    // Обов'язкові методи для перевизначення в QAbstractListModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int score() const;
    int bestScore() const;
    void setBestScore(int value);

public slots:
    // Слоти для керування рухом та станом гри з QML
    void moveUp();
    void moveDown();
    void moveLeft();
    void moveRight();
    void restart();

signals:
    void scoreChanged();
    void bestScoreChanged();
    void gameOver();
    void bombExploded();
    void tileMoved();
    void isGameActiveChanged();

private:
    QList<TileData> m_tiles; // Список активних плиток на полі
    int m_score;
    int m_bestScore;
    int m_nextId;
    bool m_gameStarted = false;

    void spawnTile();
    int getTileIndex(int r, int c) const;
    bool slideAndMerge(int dr, int dc); // Універсальний метод зсування та злиття
    void postMove();
    void cleanupDyingTiles();
    bool isGameOver() const;
};

#endif // GAMEENGINE_H