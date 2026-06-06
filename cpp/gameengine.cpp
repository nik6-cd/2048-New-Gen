#include "GameEngine.h"
#include <QRandomGenerator>
#include <QTimer>

// Конструктор: ініціалізація початкового стану моделі
GameEngine::GameEngine(QObject *parent) : QAbstractListModel(parent), m_score(0), m_bestScore(0), m_nextId(1)
{
    restart();
}

// Повертає кількість елементів (плиток) для QML View
int GameEngine::rowCount(const QModelIndex &parent) const {
    Q_UNUSED(parent);
    return m_tiles.size();
}

// Передача даних плитки в QML за відповідною роллю
QVariant GameEngine::data(const QModelIndex &index, int role) const {
    if (!index.isValid() || index.row() >= m_tiles.size()) return QVariant();
    const TileData &t = m_tiles[index.row()];

    switch(role) {
    case ValueRole: return t.v;
    case RowRole: return t.r;
    case ColRole: return t.c;
    case TypeRole: return t.t;
    case TimerRole: return t.timer;
    case DyingRole: return t.dying;
    }
    return QVariant();
}

// Реєстрація імен ролей для доступу до властивостей плитки з QML
QHash<int, QByteArray> GameEngine::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[ValueRole] = "v";
    roles[RowRole] = "row";
    roles[ColRole] = "col";
    roles[TypeRole] = "t";
    roles[TimerRole] = "timer";
    roles[DyingRole] = "dying";
    return roles;
}

int GameEngine::score() const { return m_score; }
int GameEngine::bestScore() const { return m_bestScore; }

void GameEngine::setBestScore(int value) {
    if (m_bestScore != value) {
        m_bestScore = value;
        emit bestScoreChanged();
    }
}

// Скидання гри до початкового стану
void GameEngine::restart() {
    beginResetModel();
    m_tiles.clear();
    endResetModel();

    m_score = 0;
    emit scoreChanged();

    m_gameStarted = false; // Гра почнеться лише після першого руху гравця
    emit isGameActiveChanged();

    // Створення двох стартових плиток
    spawnTile();
    spawnTile();
}

// Пошук індексу плитки за координатами (ігноруючи ті, що зникають)
int GameEngine::getTileIndex(int r, int c) const {
    for (int i = 0; i < m_tiles.size(); ++i) {
        if (m_tiles[i].r == r && m_tiles[i].c == c && !m_tiles[i].dying) {
            return i;
        }
    }
    return -1; // Клітинка порожня
}

// Генерація нової плитки на випадковому вільному місці
void GameEngine::spawnTile() {
    QList<QPair<int, int>> emptySpots;
    for (int r = 0; r < 4; ++r) {
        for (int c = 0; c < 4; ++c) {
            if (getTileIndex(r, c) == -1) emptySpots.append({r, c});
        }
    }
    if (emptySpots.isEmpty()) return;

    auto spot = emptySpots[QRandomGenerator::global()->bounded(emptySpots.size())];
    int randType = QRandomGenerator::global()->bounded(100);

    TileData newTile;
    newTile.id = m_nextId++;
    newTile.r = spot.first;
    newTile.c = spot.second;
    newTile.dying = false;

    // Визначення типу плитки (Бомба / Крига / Звичайна) та її характеристик
    if (randType < 3) {
        newTile.v = 4 << QRandomGenerator::global()->bounded(3);
        newTile.t = 2; // Бомба
        newTile.timer = 4;
    } else if (randType < 6) {
        newTile.v = 2 << QRandomGenerator::global()->bounded(3);
        newTile.t = 3; // Крига
        newTile.timer = 2;
    } else {
        newTile.v = (QRandomGenerator::global()->bounded(100) < 90) ? 2 : 4;
        newTile.t = 1; // Звичайна
        newTile.timer = 0;
    }

    // Сповіщення QML про додавання нового рядка в модель
    beginInsertRows(QModelIndex(), m_tiles.size(), m_tiles.size());
    m_tiles.append(newTile);
    endInsertRows();
}

// Основна логіка зсування та злиття плиток на полі
bool GameEngine::slideAndMerge(int dr, int dc) {
    bool moved = false;

    // Визначення порядку обходу матриці залежно від напрямку руху
    int startR = (dr == 1) ? 3 : 0;
    int endR = (dr == 1) ? -1 : 4;
    int stepR = (dr == 1) ? -1 : 1;

    int startC = (dc == 1) ? 3 : 0;
    int endC = (dc == 1) ? -1 : 4;
    int stepC = (dc == 1) ? -1 : 1;

    bool merged[4][4] = {false}; // Фіксація злиттів за поточний хід

    if (!m_gameStarted) {
        m_gameStarted = true;
        emit isGameActiveChanged();
    }

    for (int r = startR; r != endR; r += stepR) {
        for (int c = startC; c != endC; c += stepC) {
            int idx = getTileIndex(r, c);
            if (idx == -1) continue;
            if (m_tiles[idx].t == 3) continue; // Заморожені плитки не рухаються

            int targetR = r, targetC = c;

            // Пошук максимально віддаленої доступної клітинки у напрямку руху
            while (true) {
                int nextR = targetR + dr;
                int nextC = targetC + dc;
                if (nextR < 0 || nextR > 3 || nextC < 0 || nextC > 3) break;

                int nextIdx = getTileIndex(nextR, nextC);
                if (nextIdx == -1) {
                    targetR = nextR;
                    targetC = nextC;
                } else if (m_tiles[nextIdx].v == m_tiles[idx].v && !merged[nextR][nextC]) {
                    targetR = nextR;
                    targetC = nextC;
                    break;
                } else {
                    break;
                }
            }

            // Якщо позиція змінилася — переміщуємо або зливаємо
            if (targetR != r || targetC != c) {
                int targetIdx = getTileIndex(targetR, targetC);

                // Оновлюємо координати поточної плитки
                m_tiles[idx].r = targetR;
                m_tiles[idx].c = targetC;
                emit dataChanged(index(idx), index(idx), {RowRole, ColRole});

                if (targetIdx != -1) {
                    // Злиття: поточна плитка маркується як "вмираюча" (для анімації в QML)
                    m_tiles[idx].dying = true;
                    emit dataChanged(index(idx), index(idx), {DyingRole});

                    // Подвоєння значення цільової плитки та нарахування очок
                    m_tiles[targetIdx].v *= 2;
                    m_score += m_tiles[targetIdx].v;
                    merged[targetR][targetC] = true;

                    // Обробка специфічних типів при злитті (Бомба / Крига)
                    if (m_tiles[targetIdx].t == 2 || m_tiles[idx].t == 2) {
                        m_tiles[targetIdx].t = 4; // Активація вибуху бомби
                    } else if (m_tiles[targetIdx].t == 3 || m_tiles[idx].t == 3) {
                        int iceTimer = (m_tiles[targetIdx].t == 3) ? m_tiles[targetIdx].timer : m_tiles[idx].timer;
                        iceTimer--; // Зменшуємо міцність криги

                        if (iceTimer > 0) {
                            m_tiles[targetIdx].t = 3;
                            m_tiles[targetIdx].timer = iceTimer;
                        } else {
                            m_tiles[targetIdx].t = 1; // Крига розтанула, стає звичайною
                            m_tiles[targetIdx].timer = 0;
                        }
                    } else {
                        m_tiles[targetIdx].t = 1;
                    }

                    // Сповіщаємо QML про зміну стану цільової плитки
                    emit dataChanged(index(targetIdx), index(targetIdx), {ValueRole, TypeRole, TimerRole});
                }
                moved = true;
            }
        }
    }
    if (moved) emit tileMoved();
    return moved;
}

// Напрямки руху користувача
void GameEngine::moveLeft()  { if (slideAndMerge(0, -1)) postMove(); }
void GameEngine::moveRight() { if (slideAndMerge(0, 1)) postMove(); }
void GameEngine::moveUp()    { if (slideAndMerge(-1, 0)) postMove(); }
void GameEngine::moveDown()  { if (slideAndMerge(1, 0)) postMove(); }

// Обробка подій після успішного ходу (таймери, вибухи, рекорди)
void GameEngine::postMove() {
    bool exploded = false;

    // 1. Оновлення таймерів активних бомб
    for (int i = 0; i < m_tiles.size(); ++i) {
        if (m_tiles[i].dying || m_tiles[i].t != 2) continue;
        m_tiles[i].timer--;
        if (m_tiles[i].timer <= 0) {
            m_tiles[i].t = 4; // Переведення в стан вибуху
        }
        emit dataChanged(index(i), index(i), {TimerRole, TypeRole});
    }

    // 2. Розрахунок зони ураження від вибухів
    QList<QPair<int, int>> toDestroy;
    for (int i = 0; i < m_tiles.size(); ++i) {
        if (m_tiles[i].dying) continue;
        if (m_tiles[i].t == 4) {
            exploded = true;
            int r = m_tiles[i].r;
            int c = m_tiles[i].c;
            // Хрестоподібна зона вибуху (центр + 4 сусіди)
            toDestroy.append({r, c});
            toDestroy.append({r - 1, c});
            toDestroy.append({r + 1, c});
            toDestroy.append({r, c - 1});
            toDestroy.append({r, c + 1});
        }
    }

    // Анімування знищення плиток вибухом
    if (exploded) {
        emit bombExploded();
        for (auto pt : toDestroy) {
            int idx = getTileIndex(pt.first, pt.second);
            if (idx != -1) {
                m_tiles[idx].dying = true;
                emit dataChanged(index(idx), index(idx), {DyingRole});
            }
        }
    }

    // Оновлення найкращого результату
    if (m_score > m_bestScore) {
        m_bestScore = m_score;
        emit bestScoreChanged();
    }

    emit scoreChanged();
    spawnTile(); // Створення нової плитки на початку наступного ходу

    // Очищення пам'яті після завершення QML-анімацій згортання/вибуху (250 мс)
    QTimer::singleShot(250, this, &GameEngine::cleanupDyingTiles);
}

// Видалення плиток із позначкою dying з вектора моделі
void GameEngine::cleanupDyingTiles() {
    for (int i = m_tiles.size() - 1; i >= 0; --i) {
        if (m_tiles[i].dying) {
            beginRemoveRows(QModelIndex(), i, i);
            m_tiles.removeAt(i);
            endRemoveRows();
        }
    }
    if (isGameOver()) emit gameOver();
}

// Перевірка умов завершення гри (відсутність можливих ходів)
bool GameEngine::isGameOver() const {
    for (int r = 0; r < 4; ++r) {
        for (int c = 0; c < 4; ++c) {
            int idx = getTileIndex(r, c);

            if (idx == -1) continue;
            if (m_tiles[idx].t == 3) continue; // Заморожена плитка заблокована за замовчуванням

            // Перевірка 4-х сусідніх напрямків
            int dr[] = {-1, 1, 0, 0};
            int dc[] = {0, 0, -1, 1};

            for (int i = 0; i < 4; ++i) {
                int nr = r + dr[i];
                int nc = c + dc[i];

                if (nr >= 0 && nr < 4 && nc >= 0 && nc < 4) {
                    int nIdx = getTileIndex(nr, nc);

                    // Якщо є вільне місце поруч — хід можливий
                    if (nIdx == -1) return false;

                    // Якщо є сусід з таким же номіналом — можливе злиття
                    if (m_tiles[idx].v == m_tiles[nIdx].v) return false;
                }
            }
        }
    }

    // Якщо жодна активна плитка не має доступних ходів чи злиттів
    return true;
}