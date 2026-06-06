#ifndef GAMEENGINE_H
#define GAMEENGINE_H

#include <QAbstractListModel>
#include <QList>

// Структура плитки. Обрати внимание: добавились row, col и флаг dying
struct TileData {
    int id;       // Уникальный ID плитки
    int r;        // Текущая строка
    int c;        // Текущая колонка
    int v;        // Номинал
    int t;        // Тип (1=Обычная, 2=Бомба, 3=Лед, 4=Взрыв)
    int timer;    // Таймер бомбы
    bool dying;   // Флаг удаления (для анимации исчезновения после слияния)
};

class GameEngine : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int score READ score NOTIFY scoreChanged)
    Q_PROPERTY(int bestScore READ bestScore WRITE setBestScore NOTIFY bestScoreChanged)
    Q_PROPERTY(bool isGameActive READ isGameActive NOTIFY isGameActiveChanged)

public:
    // Роли для маппинга переменных в QML
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

    // Обязательные методы QAbstractListModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int score() const;
    int bestScore() const;
    void setBestScore(int value);

public slots:
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
    QList<TileData> m_tiles; // Список активных плиток
    int m_score;
    int m_bestScore;
    int m_nextId;
    bool m_gameStarted = false;

    void spawnTile();
    int getTileIndex(int r, int c) const;
    bool slideAndMerge(int dr, int dc); // Универсальный сдвиг во все 4 стороны
    void postMove();
    void cleanupDyingTiles();
    bool isGameOver() const;
};

#endif // GAMEENGINE_H