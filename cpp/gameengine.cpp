#include "GameEngine.h"
#include <QRandomGenerator>
#include <QTimer>

GameEngine::GameEngine(QObject *parent) : QAbstractListModel(parent), m_score(0), m_bestScore(0), m_nextId(1)
{
    restart();
}

int GameEngine::rowCount(const QModelIndex &parent) const {
    Q_UNUSED(parent);
    return m_tiles.size();
}

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

void GameEngine::restart() {
    beginResetModel();
    m_tiles.clear();
    endResetModel();

    m_score = 0;
    emit scoreChanged();

    m_gameStarted = false; // Игра еще не начата
    emit isGameActiveChanged();

    spawnTile();
    spawnTile();
}

int GameEngine::getTileIndex(int r, int c) const {
    for (int i = 0; i < m_tiles.size(); ++i) {
        if (m_tiles[i].r == r && m_tiles[i].c == c && !m_tiles[i].dying) {
            return i;
        }
    }
    return -1; // Пусто
}

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

    if (randType < 3) {
        newTile.v = 4 << QRandomGenerator::global()->bounded(3);
        newTile.t = 2; // Бомба
        newTile.timer = 4;
    } else if (randType < 6) {
        newTile.v = 2 << QRandomGenerator::global()->bounded(3);
        newTile.t = 3; // Лед
        newTile.timer = 2;
    } else {
        newTile.v = (QRandomGenerator::global()->bounded(100) < 90) ? 2 : 4;
        newTile.t = 1; // Обычная
        newTile.timer = 0;
    }

    // Сообщаем QML о добавлении новой плитки
    beginInsertRows(QModelIndex(), m_tiles.size(), m_tiles.size());
    m_tiles.append(newTile);
    endInsertRows();
}

bool GameEngine::slideAndMerge(int dr, int dc) {
    bool moved = false;
    // Определяем порядок обхода в зависимости от направления сдвига
    int startR = (dr == 1) ? 3 : 0;
    int endR = (dr == 1) ? -1 : 4;
    int stepR = (dr == 1) ? -1 : 1;

    int startC = (dc == 1) ? 3 : 0;
    int endC = (dc == 1) ? -1 : 4;
    int stepC = (dc == 1) ? -1 : 1;

    bool merged[4][4] = {false};

    if (!m_gameStarted) {
        m_gameStarted = true; // Считаем, что игра пошла с первого движения
        emit isGameActiveChanged();
    }

    for (int r = startR; r != endR; r += stepR) {
        for (int c = startC; c != endC; c += stepC) {
            int idx = getTileIndex(r, c);
            if (idx == -1) continue;
            if (m_tiles[idx].t == 3) continue; // Замороженные игнорируем

            int targetR = r, targetC = c;

            // Ищем крайнюю доступную клетку
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

            if (targetR != r || targetC != c) {
                int targetIdx = getTileIndex(targetR, targetC);

                // Двигаем текущую плитку
                m_tiles[idx].r = targetR;
                m_tiles[idx].c = targetC;
                emit dataChanged(index(idx), index(idx), {RowRole, ColRole});

                if (targetIdx != -1) {
                    // Произошло слияние! Текущая плитка умирает (уйдет в прозрачность)
                    m_tiles[idx].dying = true;
                    emit dataChanged(index(idx), index(idx), {DyingRole});

                    // Целевая плитка удваивается
                    m_tiles[targetIdx].v *= 2;
                    m_score += m_tiles[targetIdx].v;
                    merged[targetR][targetC] = true;

                    // Логика типов
                    // Логика типов
                    if (m_tiles[targetIdx].t == 2 || m_tiles[idx].t == 2) {
                        m_tiles[targetIdx].t = 4; // Бомба всегда взрывается при слиянии
                    } else if (m_tiles[targetIdx].t == 3 || m_tiles[idx].t == 3) {
                        // Если одна из плиток - лед, берем ее "здоровье"
                        int iceTimer = (m_tiles[targetIdx].t == 3) ? m_tiles[targetIdx].timer : m_tiles[idx].timer;
                        iceTimer--; // Наносим урон льду

                        if (iceTimer > 0) {
                            m_tiles[targetIdx].t = 3; // Все еще лед
                            m_tiles[targetIdx].timer = iceTimer;
                        } else {
                            m_tiles[targetIdx].t = 1; // Растаяла! Становится обычной
                            m_tiles[targetIdx].timer = 0;
                        }
                    } else {
                        m_tiles[targetIdx].t = 1;
                    }

                    // Обновляем TimerRole тоже, чтобы интерфейс перерисовался
                    emit dataChanged(index(targetIdx), index(targetIdx), {ValueRole, TypeRole, TimerRole});
                }
                moved = true;
            }
        }
    }
    if (moved) emit tileMoved();
    return moved;
}

void GameEngine::moveLeft()  { if (slideAndMerge(0, -1)) postMove(); }
void GameEngine::moveRight() { if (slideAndMerge(0, 1)) postMove(); }
void GameEngine::moveUp()    { if (slideAndMerge(-1, 0)) postMove(); }
void GameEngine::moveDown()  { if (slideAndMerge(1, 0)) postMove(); }

void GameEngine::postMove() {
    bool exploded = false;

    // 1. Таймеры
    for (int i = 0; i < m_tiles.size(); ++i) {
        if (m_tiles[i].dying || m_tiles[i].t != 2) continue;
        m_tiles[i].timer--;
        if (m_tiles[i].timer <= 0) {
            m_tiles[i].t = 4;
        }
        emit dataChanged(index(i), index(i), {TimerRole, TypeRole});
    }

    // 2. Взрывы
    QList<QPair<int, int>> toDestroy;
    for (int i = 0; i < m_tiles.size(); ++i) {
        if (m_tiles[i].dying) continue;
        if (m_tiles[i].t == 4) {
            exploded = true;
            int r = m_tiles[i].r;
            int c = m_tiles[i].c;
            toDestroy.append({r, c});
            toDestroy.append({r - 1, c});
            toDestroy.append({r + 1, c});
            toDestroy.append({r, c - 1});
            toDestroy.append({r, c + 1});
        }
    }

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

    if (m_score > m_bestScore) {
        m_bestScore = m_score;
        emit bestScoreChanged();
    }

    emit scoreChanged();
    spawnTile();

    // Ждем 250мс (пока пройдет QML анимация слияния) и удаляем мертвые плитки из памяти
    QTimer::singleShot(250, this, &GameEngine::cleanupDyingTiles);
}

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

bool GameEngine::isGameOver() const {
    // Проверяем каждую клетку на поле
    for (int r = 0; r < 4; ++r) {
        for (int c = 0; c < 4; ++c) {
            int idx = getTileIndex(r, c);

            // Если клетки нет, идем дальше. Сама по себе пустая клетка ход не делает.
            if (idx == -1) continue;

            // Если плитка заморожена (лед), она не может инициировать сдвиг
            if (m_tiles[idx].t == 3) continue;

            // Смотрим 4 направления вокруг НЕ замороженной плитки
            int dr[] = {-1, 1, 0, 0};
            int dc[] = {0, 0, -1, 1};

            for (int i = 0; i < 4; ++i) {
                int nr = r + dr[i];
                int nc = c + dc[i];

                if (nr >= 0 && nr < 4 && nc >= 0 && nc < 4) {
                    int nIdx = getTileIndex(nr, nc);

                    // 1. Если рядом есть пустое место — мы можем туда шагнуть (ход есть!)
                    if (nIdx == -1) return false;

                    // 2. Если рядом плитка с таким же номиналом — мы можем слиться (даже если сосед — лед)
                    if (m_tiles[idx].v == m_tiles[nIdx].v) return false;
                }
            }
        }
    }

    // Если мы проверили всё поле, и ни одна обычная плитка не может походить
    // (все заблокированы стенками, льдом или другими номиналами) — это честный Game Over.
    return true;
}